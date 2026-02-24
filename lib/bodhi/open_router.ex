defmodule Bodhi.OpenRouter do
  @moduledoc """
  OpenRouter API wrapper.

  Provides unified access to multiple AI models through
  OpenAI-compatible API. Supports database-backed model
  configuration with multi-model fallback via OpenRouter's
  `models` array and `route: "fallback"`.
  """
  @behaviour Bodhi.Behaviours.LLMProvider

  @openrouter_url "https://openrouter.ai/api/v1/chat/completions"
  @models_url "https://openrouter.ai/api/v1/models"
  @default_model "openrouter/free"
  @cache_key :active_llm_configs
  @cache_ttl :timer.minutes(5)

  alias Bodhi.Cache
  alias Bodhi.Chats.Message
  alias Bodhi.LlmConfigs
  alias Bodhi.LlmConfigs.LlmConfig
  alias Bodhi.Prompts
  alias Bodhi.Prompts.Prompt

  require Logger

  @doc """
  Fetches all available models from the OpenRouter API.

  Returns `{:ok, models}` where `models` is a list of maps
  with at least `"id"` and `"name"` keys.
  """
  @impl true
  @spec fetch_models() ::
          {:ok, [map()]} | {:error, String.t()}
  def fetch_models do
    :get
    |> Finch.build(@models_url, [
      {"Authorization", "Bearer #{Application.get_env(:bodhi, :openrouter_token)}"}
    ])
    |> Finch.request!(LLM)
    |> handle_finch_response()
    |> Jason.decode!()
    |> case do
      %{"data" => models} -> {:ok, models}
      other -> {:error, "Unexpected response: #{inspect(other)}"}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  @doc """
  Request OpenRouter for bot's response in dialogue.
  """
  @impl true
  @spec ask_llm([Message.t()]) ::
          {:ok, String.t()} | {:error, String.t()}
  def ask_llm(messages) do
    %Prompt{text: prompt} = Prompts.get_latest_prompt!()
    configs = resolve_config()

    messages
    |> prepare_messages()
    |> request_openrouter(prompt, configs)
    |> parse_response()
  end

  @doc """
  Returns active LLM configs from cache or database.

  Results are cached for 5 minutes. Returns an empty list
  when no active configs exist (falls back to default model).
  """
  @spec resolve_config() :: [LlmConfig.t()]
  def resolve_config do
    case Cache.get(@cache_key) do
      nil ->
        configs = LlmConfigs.get_active_configs()
        Cache.put(@cache_key, configs, ttl: @cache_ttl)
        configs

      configs ->
        configs
    end
  end

  @doc """
  Builds the JSON request body for OpenRouter.

  - Single active model: uses `model` key
  - Multiple active models: uses `models` array +
    `route: "fallback"`
  - No DB config: uses `@default_model`
  - Temperature/max_tokens from highest-priority config
  """
  @spec build_body([map()], String.t(), [LlmConfig.t()]) ::
          String.t()
  def build_body(messages, prompt, configs) do
    all_messages = [
      %{role: "system", content: prompt} | messages
    ]

    %{messages: all_messages}
    |> put_model_config(configs)
    |> put_optional_params(configs)
    |> Jason.encode!()
  end

  defp prepare_messages(messages) do
    Enum.map(messages, &build_message/1)
  end

  defp build_message(%Message{text: text, chat_id: user_id, user_id: user_id}),
    do: %{role: "user", content: text}

  defp build_message(%Message{text: text}),
    do: %{role: "assistant", content: text}

  defp request_openrouter(messages, prompt, configs) do
    body = build_body(messages, prompt, configs)

    :post
    |> Finch.build(
      @openrouter_url,
      [
        {"Authorization", "Bearer #{Application.get_env(:bodhi, :openrouter_token)}"},
        {"Content-Type", "application/json"},
        {"HTTP-Referer", BodhiWeb.Endpoint.url()},
        {"X-Title", "Lama Bot"}
      ],
      body
    )
    |> Finch.request!(LLM)
    |> handle_finch_response()
    |> Jason.decode!()
  end

  defp put_model_config(body, []) do
    Map.put(body, :model, @default_model)
  end

  defp put_model_config(body, [single]) do
    Map.put(body, :model, single.model)
  end

  defp put_model_config(body, configs) do
    models = Enum.map(configs, & &1.model)

    body
    |> Map.put(:models, models)
    |> Map.put(:route, "fallback")
  end

  defp put_optional_params(body, []) do
    body
  end

  defp put_optional_params(body, [primary | _]) do
    body
    |> maybe_put(:temperature, primary.temperature)
    |> maybe_put(:max_tokens, primary.max_tokens)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp handle_finch_response(%Finch.Response{status: 200, body: body}),
    do: body

  defp handle_finch_response(%Finch.Response{status: code, body: body}) do
    Logger.warning("OpenRouter request error code: #{code}, body: '#{body}'")

    body
  end

  defp parse_response(%{
         "choices" => [%{"message" => %{"content" => content}} | _]
       }) do
    {:ok, content}
  end

  defp parse_response(%{"error" => error}) do
    Logger.error("OpenRouter API error: #{inspect(error)}")
    {:error, "OpenRouter API error: #{inspect(error)}"}
  end

  defp parse_response(response) do
    Logger.error("Unexpected OpenRouter response format: #{inspect(response)}")

    {:error, "Unexpected response format"}
  end
end
