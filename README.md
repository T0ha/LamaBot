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

#### Google Gemini (Default)
- **Module:** `Bodhi.Gemini`
- **Model:** `gemini-2.0-flash`
- **Environment Variable:** `GEMINI_API_KEY`

#### OpenRouter
- **Module:** `Bodhi.OpenRouter`
- **Default Model:** `anthropic/claude-3.5-sonnet`
- **Environment Variable:** `OPENROUTER_API_KEY`
- **Website:** https://openrouter.ai/

### Switching Providers

To switch AI providers, update `config/config.exs`:

```elixir
# Use Google Gemini (default)
config :bodhi, :ai_client, Bodhi.Gemini

# Use OpenRouter
config :bodhi, :ai_client, Bodhi.OpenRouter
```

### Setting Up API Keys

1. **Google Gemini:**
   - Get API key from: https://aistudio.google.com/app/apikey
   - Set in `.envrc`: `export GEMINI_API_KEY=your_api_key_here`

2. **OpenRouter:**
   - Get API key from: https://openrouter.ai/keys
   - Set in `.envrc`: `export OPENROUTER_API_KEY=sk-or-v1-your_api_key_here`

3. Reload environment: `direnv allow` (if using direnv)

### Changing OpenRouter Model

Edit `lib/bodhi/open_router.ex` and modify the `@default_model` attribute:

```elixir
@default_model "anthropic/claude-3.5-sonnet"  # Current default

# Other popular models:
# @default_model "openai/gpt-4-turbo"
# @default_model "meta-llama/llama-3.1-70b-instruct"
# @default_model "google/gemini-pro-1.5"
```

See all available models at: https://openrouter.ai/models

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
