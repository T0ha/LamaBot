defmodule Bodhi.LLM.ResponseTest do
  use ExUnit.Case, async: true

  alias Bodhi.LLM.Response

  describe "struct" do
    test "creates with required content" do
      response = %Response{content: "Hello"}
      assert response.content == "Hello"
      assert response.ai_model == nil
      assert response.prompt_tokens == nil
      assert response.completion_tokens == nil
    end

    test "creates with all fields" do
      response = %Response{
        content: "Hello",
        ai_model: "gpt-4",
        prompt_tokens: 10,
        completion_tokens: 20
      }

      assert response.content == "Hello"
      assert response.ai_model == "gpt-4"
      assert response.prompt_tokens == 10
      assert response.completion_tokens == 20
    end

    test "raises on missing content" do
      assert_raise ArgumentError, fn ->
        struct!(Response, %{ai_model: "gpt-4"})
      end
    end
  end
end
