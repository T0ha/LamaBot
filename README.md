# Bodhi

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## AI Provider Configuration

Bodhi supports multiple AI providers that can be switched via configuration.

### Available Providers

#### OpenRouter (Default)
- **Module:** `Bodhi.OpenRouter`
- **Default Model:** `openrouter/free` (when no model is selected in admin)
- **Environment Variable:** `OPENROUTER_API_KEY`
- **Website:** https://openrouter.ai/

#### Google Gemini
- **Module:** `Bodhi.Gemini`
- **Model:** `gemini-2.0-flash`
- **Environment Variable:** `GEMINI_API_KEY`

### Switching Providers

To switch AI providers, update `config/config.exs`:

```elixir
# Use OpenRouter (default)
config :bodhi, :llm_provider, Bodhi.OpenRouter

# Use Google Gemini
config :bodhi, :llm_provider, Bodhi.Gemini
```

### Setting Up API Keys

1. **OpenRouter:**
   - Get API key from: https://openrouter.ai/keys
   - Set in `.envrc`: `export OPENROUTER_API_KEY=sk-or-v1-your_api_key_here`

2. **Google Gemini:**
   - Get API key from: https://aistudio.google.com/app/apikey
   - Set in `.envrc`: `export GEMINI_API_KEY=your_api_key_here`

3. Reload environment: `direnv allow` (if using direnv)

### Selecting an OpenRouter Model

In the admin UI, open **LLM Configurations**, choose **Sync Models** to
load available OpenRouter models, then edit a model to set optional
temperature and max token values. Choose **Use this model** to select one
model for the bot. Choose **Use default model** to clear the selection and
return to `openrouter/free`.

## Features

### Daily Dialog Summarization

Bodhi automatically summarizes chat conversations daily to optimize AI context and reduce API costs:

- **Automatic Summarization**: Worker runs daily at 2 AM UTC to summarize previous day's messages
- **Smart Context Assembly**: Uses summaries for older messages + full messages from last 7 days
- **Cost Optimization**: Reduces token usage by ~80-90% for long conversations
- **Seamless Integration**: Falls back gracefully when no summaries exist

**Example Results:**
- 265 total messages → 4 recent messages in context
- **98.5% token reduction** for older conversations

#### Documentation

- **[docs/SUMMARIZATION.md](docs/SUMMARIZATION.md)** - Complete guide to the summarization system
- **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Deployment and backfill procedures

#### Quick Start

After deployment, backfill historical summaries:

```bash
# Preview what will be processed (no API calls)
bin/bodhi eval "Bodhi.Release.backfill_summaries(dry_run: true)"

# Run the backfill
bin/bodhi eval "Bodhi.Release.backfill_summaries()"
```

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for detailed instructions.

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
