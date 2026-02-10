# Deployment Guide

## Database Migrations

After deploying a new version, run database migrations:

```bash
bin/bodhi eval "Bodhi.Release.migrate()"
```

## Post-Deployment Tasks

### Backfill Message Summaries (After Summarization Feature Deployment)

After deploying the summarization feature for the first time, you should backfill summaries for historical messages.

#### Step 1: Preview (Dry Run)

First, run a dry run to see what would be processed without making any AI calls:

```bash
bin/bodhi eval "Bodhi.Release.backfill_summaries(dry_run: true)"
```

This will show:
- How many chats will be processed
- How many days have messages for each chat
- How many summaries would be created
- How many days would be skipped (no messages or already have summaries)

#### Step 2: Estimate Costs

Calculate AI API costs based on the dry run output. Each summary requires one AI API call.

Example calculation:
- Chat 1: 100 days with messages = 100 API calls
- Chat 2: 50 days with messages = 50 API calls
- Total: 150 API calls × $0.XX per call = $XX.XX

#### Step 3: Run Backfill

Once you've confirmed the scope and cost, run the actual backfill:

```bash
# Full backfill (all chats, all dates)
bin/bodhi eval "Bodhi.Release.backfill_summaries()"

# Or with specific parameters
bin/bodhi eval "Bodhi.Release.backfill_summaries(from_date: ~D[2024-01-01], to_date: ~D[2024-12-31])"

# Or for specific chats only
bin/bodhi eval "Bodhi.Release.backfill_summaries(chat_ids: [123, 456])"
```

#### Step 4: Monitor Progress

Monitor the logs for progress and any errors:

```bash
tail -f /path/to/logs/production.log | grep -E "backfill|summary"
```

You should see logs like:
```
[info] Starting summary backfill (dry_run: false)
[info] Found 5 chats to process
[info] Processing chat 123 from 2024-01-01 to 2024-12-31
[debug] Creating summary for chat 123 on 2024-01-01 (15 messages)
[info] Chat 123: 365 summaries created, 0 days skipped
[info] Backfill complete: 5 chats processed, 1825 summaries created
```

#### Step 5: Verify Results

Check that summaries were created:

```bash
bin/bodhi eval "Bodhi.Repo.aggregate(Bodhi.Chats.Summary, :count)"
```

## Rollback Procedure

If you need to rollback a deployment:

```bash
# Rollback to a specific migration version
bin/bodhi eval "Bodhi.Release.rollback(Bodhi.Repo, VERSION_NUMBER)"
```

## Troubleshooting

### Backfill Fails with AI API Errors

If the backfill fails due to AI API rate limiting or errors:

1. The backfill is idempotent - you can safely re-run it
2. It will skip dates that already have summaries
3. Consider using date ranges to backfill in smaller batches:

```bash
# Backfill one month at a time
bin/bodhi eval "Bodhi.Release.backfill_summaries(from_date: ~D[2024-01-01], to_date: ~D[2024-01-31])"
bin/bodhi eval "Bodhi.Release.backfill_summaries(from_date: ~D[2024-02-01], to_date: ~D[2024-02-29])"
# etc.
```

### Out of Memory

If the backfill runs out of memory with many chats:

1. Process chats in batches using the `chat_ids` parameter:

```bash
# Get list of chat IDs first
bin/bodhi eval "Bodhi.Repo.all(Ecto.Query.from m in Bodhi.Chats.Message, distinct: m.chat_id, select: m.chat_id)"

# Then backfill in batches
bin/bodhi eval "Bodhi.Release.backfill_summaries(chat_ids: [1, 2, 3])"
bin/bodhi eval "Bodhi.Release.backfill_summaries(chat_ids: [4, 5, 6])"
# etc.
```

## Scheduled Tasks

The summarization worker runs automatically daily at 2 AM UTC via Oban cron. No manual intervention needed for daily summaries after the initial backfill.

Monitor scheduled tasks via the Oban dashboard at `/oban` in your web interface (requires admin access).
