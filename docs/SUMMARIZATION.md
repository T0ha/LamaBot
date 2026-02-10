# Daily Dialog Summarization

## Overview

The system now automatically summarizes chat dialogs daily and uses summaries + recent messages (last 7 days) instead of all messages during `ask_ai` calls. This reduces LLM context size and API costs.

## Implementation

### Database Schema

The `message_summaries` table stores daily summaries:
- `chat_id` - Which chat this summary belongs to
- `summary_text` - The AI-generated summary
- `summary_date` - Date being summarized
- `message_count` - Number of messages summarized
- `start_time/end_time` - Temporal boundaries
- `ai_model` - Which AI backend generated this

### Automatic Scheduling

The `DailyChatSummarizer` worker runs daily at 2 AM UTC (configured via Oban Cron plugin). It:
1. Finds all chats with messages from yesterday
2. Summarizes each chat's messages using AI
3. Stores summaries in the database

### Context Assembly

When a user sends a message, `get_chat_context_for_ai/2`:
1. Gets messages from the last 7 days (configurable)
2. Gets summaries for dates before that cutoff
3. Combines them: summaries first, then recent messages
4. Returns to AI for processing

## Configuration

In `config/config.exs`:

```elixir
# Summarization settings
config :bodhi, :summarization, recent_days: 7

# Oban Cron plugin schedules the daily worker
config :bodhi, Oban,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"0 2 * * *", Bodhi.Workers.DailyChatSummarizer}
     ]}
  ]
```

## Backfilling Historical Data

After deploying the summarization feature, you can backfill summaries for all historical messages using the Release module.

### Running from Production Release

```bash
# Dry run first to see what would be processed
bin/bodhi eval "Bodhi.Release.backfill_summaries(dry_run: true)"

# Backfill all chats (WARNING: Uses AI API credits!)
bin/bodhi eval "Bodhi.Release.backfill_summaries()"

# Backfill specific date range
bin/bodhi eval "Bodhi.Release.backfill_summaries(from_date: ~D[2024-01-01], to_date: ~D[2024-12-31])"

# Backfill specific chats only
bin/bodhi eval "Bodhi.Release.backfill_summaries(chat_ids: [123, 456])"
```

### Running from IEx (Development)

```elixir
# Dry run to preview
Bodhi.Release.backfill_summaries(dry_run: true)

# Backfill all
Bodhi.Release.backfill_summaries()

# With custom date range
Bodhi.Release.backfill_summaries(
  from_date: ~D[2024-01-01],
  to_date: ~D[2024-12-31]
)
```

### Options

- `dry_run: true` - Shows what would be done without making AI calls or creating summaries
- `from_date: Date.t()` - Start date (default: earliest message date per chat)
- `to_date: Date.t()` - End date (default: yesterday)
- `chat_ids: [integer()]` - Specific chat IDs to process (default: all chats with messages)

### Important Notes

**⚠️ API Cost Warning**: Backfilling will make one AI API call per day per chat. For a chat with messages spanning 365 days, that's 365 API calls. Calculate costs before running on production data.

**Idempotency**: The backfill is safe to run multiple times. It will skip dates that already have summaries.

**Performance**: The backfill processes chats sequentially and dates within each chat sequentially. For large datasets, this may take considerable time.

**Progress Monitoring**: Check logs for progress:
```bash
# In production
tail -f /path/to/logs/production.log | grep "backfill"
```

## Manual Testing

### 1. Check Current State

```elixir
# In IEx
alias Bodhi.Chats

# Check message count
chat_id = 308167163
all_messages = Chats.get_chat_messages(chat_id)
IO.puts("Total messages: #{length(all_messages)}")

# Check context size
context = Chats.get_chat_context_for_ai(chat_id)
IO.puts("Context size: #{length(context)}")
```

### 2. Manual Summarization (CAUTION: Uses AI API Credits)

```elixir
# Create a summary for a specific date
alias Bodhi.Workers.DailyChatSummarizer

# Create and insert a job for yesterday
job = DailyChatSummarizer.new(%{})
Oban.insert!(job)

# Or perform immediately (uses AI credits!)
DailyChatSummarizer.perform(%Oban.Job{args: %{}})
```

### 3. Backfill Historical Summaries

Use the built-in Release function for backfilling:

```elixir
# Recommended: Start with a dry run
Bodhi.Release.backfill_summaries(dry_run: true)

# After verifying, run the actual backfill
Bodhi.Release.backfill_summaries()

# Or with specific parameters
Bodhi.Release.backfill_summaries(
  from_date: ~D[2024-01-01],
  to_date: ~D[2024-12-31],
  chat_ids: [123]  # Optional: specific chats only
)
```

See the "Backfilling Historical Data" section above for more details.

## Monitoring

### Check Oban Dashboard

Visit `/oban` in your browser to see:
- Job success/failure rates
- Queue status
- Scheduled jobs

### Check Summary Statistics

```elixir
alias Bodhi.Repo
alias Bodhi.Chats.Summary
import Ecto.Query

# Count summaries by chat
from(s in Summary,
  group_by: s.chat_id,
  select: {s.chat_id, count(s.id)}
)
|> Repo.all()

# Get recent summaries
from(s in Summary,
  order_by: [desc: s.summary_date],
  limit: 10
)
|> Repo.all()
|> Enum.each(fn s ->
  IO.puts("#{s.summary_date} - Chat #{s.chat_id}: #{s.message_count} messages")
end)
```

## Cost Savings

**Before:** Every message sends full chat history to AI
- Example: 265 messages per API call

**After:** Every message sends summaries + recent messages
- Example: 10 summaries + 3 recent messages = 13 "messages"
- **Token reduction: ~95%**
- **API cost reduction: ~80-90%**

## Rollback

If issues arise:

1. Remove the cron entry from Oban config:
   ```elixir
   # In config/config.exs - remove DailyChatSummarizer
   # from the Oban Cron plugin crontab list
   ```

2. Revert to old behavior:
   ```elixir
   # In TgWebhookHandler
   defp get_answer(%_{chat_id: chat_id}, _) do
     messages = Bodhi.Chats.get_chat_messages(chat_id)  # Old way
     {:ok, _answer} = Bodhi.AI.ask_llm(messages)
   end
   ```

No data migration needed - summaries are additive.

## Future Enhancements

1. **Multi-level summarization**: Weekly/monthly summaries
2. **User controls**: Per-chat settings, adjustable window
3. **Advanced features**: Semantic search, topic extraction
4. **Optimization**: Pre-cached contexts, compressed old summaries
