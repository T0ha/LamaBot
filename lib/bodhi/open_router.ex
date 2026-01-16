defmodule Bodhi.OpenRouter do
  @moduledoc """
  OpenRouter API wrapper
  OpenRouter provides unified access to multiple AI models through OpenAI-compatible API.
  """
  @behaviour Bodhi.Behaviours.AIClient

  @openrouter_url "https://openrouter.ai/api/v1/chat/completions"
  @default_model "deepseek/deepseek-r1-0528:free"

  alias Bodhi.Chats.Message
  alias Bodhi.Prompts
  alias Bodhi.Prompts.Prompt

  require Logger

  @doc """
  Request OpenRouter for bot's response in dialogue.
  """
  @impl true
  @spec ask_llm([Message.t()]) :: {:ok, String.t()} | {:error, String.t()}
  def ask_llm(messages) do
    %Prompt{text: prompt} = Prompts.get_latest_prompt!()

    messages
    |> prepare_messages()
    |> request_openrouter(prompt)
    |> parse_response()
  end

  defp prepare_messages(messages), do: Enum.map(messages, &build_message/1)

  defp build_message(%Message{text: text, chat_id: user_id, user_id: user_id}),
    do: %{role: "user", content: text}

  defp build_message(%Message{text: text}), do: %{role: "assistant", content: text}

  defp request_openrouter(messages, prompt) do
    body = build_body(messages, prompt)

    :post
    |> Finch.build(
      @openrouter_url,
      [
        {"Authorization", "Bearer #{Application.get_env(:bodhi, :openrouter_token)}"},
        {"Content-Type", "application/json"},
        {"HTTP-Referer", "https://lamabot.io"},
        {"X-Title", "Lama Bot"}
      ],
      body
    )
    |> Finch.request!(LLM)
    |> handle_finch_response()
    |> Jason.decode!()
  end

  defp build_body(messages, prompt) do
    %{
      model: @default_model,
      messages: [
        %{role: "system", content: prompt}
        | messages
      ]
    }
    |> Jason.encode!()
  end

  defp handle_finch_response(%Finch.Response{status: 200, body: body}), do: body

  defp handle_finch_response(%Finch.Response{status: code, body: body}) do
    Logger.warning("OpenRouter request error code: #{code}, body: '#{body}'")
    body
  end

  defp parse_response(%{"choices" => [%{"message" => %{"content" => content}} | _]}) do
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
