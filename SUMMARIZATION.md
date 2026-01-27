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
config :bodhi, :summarization,
  enabled: true,
  recent_days: 7,  # Context window
  schedule: "0 2 * * *"  # Cron expression
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

To create summaries for past dates, you can create a migration or run a script:

```elixir
# WARNING: This will consume AI API credits for each day!
alias Bodhi.Chats
alias Bodhi.Workers.DailyChatSummarizer

# Get the date range
start_date = ~D[2024-01-01]
end_date = Date.utc_today() |> Date.add(-1)

# Create a job for each day
Date.range(start_date, end_date)
|> Enum.each(fn date ->
  # Check if there are active chats on this date
  active_chats = Chats.get_active_chats_for_date(date)

  if length(active_chats) > 0 do
    IO.puts("Processing #{date} (#{length(active_chats)} chats)")
    # You would need to modify the worker to accept a date parameter
    # or create summaries manually here
  end
end)
```

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

1. Disable scheduler:
   ```elixir
   # In config
   config :bodhi, :summarization, enabled: false
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
