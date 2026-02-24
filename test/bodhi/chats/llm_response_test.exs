defmodule Bodhi.Chats.LlmResponseTest do
  use Bodhi.DataCase

  alias Bodhi.Chats
  alias Bodhi.Chats.LlmResponse

  describe "create_llm_response/1" do
    test "creates with valid attrs" do
      attrs = %{
        ai_model: "openrouter/gpt-4",
        prompt_tokens: 100,
        completion_tokens: 50
      }

      assert {:ok, %LlmResponse{} = resp} =
               Chats.create_llm_response(attrs)

      assert resp.ai_model == "openrouter/gpt-4"
      assert resp.prompt_tokens == 100
      assert resp.completion_tokens == 50
    end

    test "rejects empty attrs (ai_model required)" do
      assert {:error, changeset} =
               Chats.create_llm_response(%{})

      assert %{ai_model: ["can't be blank"]} =
               errors_on(changeset)
    end
  end

  describe "message association" do
    test "message can reference llm_response via FK" do
      llm_resp = insert(:llm_response)
      chat = insert(:chat)
      user = chat.user

      {:ok, message} =
        Chats.create_message(%{
          text: "test",
          chat_id: chat.id,
          user_id: user.id,
          llm_response_id: llm_resp.id
        })

      assert message.llm_response_id == llm_resp.id

      loaded =
        message
        |> Repo.preload(:llm_response)

      assert loaded.llm_response.id == llm_resp.id
      assert loaded.llm_response.ai_model == llm_resp.ai_model
    end
  end
end
