defmodule Bodhi.Gemini do
  @moduledoc """
  Google Gemini API wrapper
  """
  @gemini_url "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

  alias Bodhi.Chats.Message
  alias Bodhi.Prompts
  alias Bodhi.Prompts.Prompt

  require Logger

  def ask_gemini(messages) do
    %Prompt{text: prompt} = Prompts.get_latest_prompt!()

    messages
    |> prepare_messages()
    |> request_gemini(prompt)
    |> parse_response()
    |> parse_message()
  end

  defp prepare_messages(messages), do: Enum.map(messages, &build_message/1)

  defp build_message(%Message{text: text, chat_id: user_id, user_id: user_id}),
    do: %{role: :user, parts: [%{text: text}]}

  defp build_message(%Message{text: text}), do: %{role: :model, parts: [%{text: text}]}

  defp request_gemini(messages, prompt) do
    body = build_body(messages, prompt)

    :post
    |> Finch.build(
      @gemini_url,
      [{"x-goog-api-key", Application.get_env(:bodhi, :gemini_token)}],
      body
    )
    |> Finch.request!(Gemini)
    |> handle_finch_response()
    |> Jason.decode!()
  end

  defp build_body(messages, prompt) do
    %{
      system_instruction: %{
        parts: %{
          text: prompt
        }
      },
      contents: messages
    }
    |> Jason.encode!()
  end

  defp handle_finch_response(%Finch.Response{status: 200, body: body}), do: body

  defp handle_finch_response(%Finch.Response{status: code, body: body}) do
    Logger.warning("Gemini request error code: #{code}, body: '#{body}'")
    body
  end

  defp parse_response(%{"candidates" => [%{"content" => content}]}), do: content

  defp parse_message(%{"parts" => [%{"text" => text}]}) do
    {:ok, text}
  end
end
