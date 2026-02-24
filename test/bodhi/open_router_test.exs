defmodule Bodhi.OpenRouterTest do
  use Bodhi.DataCase, async: false

  alias Bodhi.Cache
  alias Bodhi.OpenRouter

  setup do
    Cache.delete_all()
    :ok
  end

  describe "resolve_config/0" do
    test "returns active DB configs from cache" do
      c1 =
        insert(:llm_config,
          active: true,
          position: 0,
          model: "openai/gpt-4o",
          temperature: 0.7,
          max_tokens: 4096
        )

      c2 =
        insert(:llm_config,
          active: true,
          position: 1,
          model: "anthropic/claude-3.5-sonnet"
        )

      insert(:llm_config, active: false, position: 2)

      result = OpenRouter.resolve_config()

      assert length(result) == 2
      assert Enum.map(result, & &1.id) == [c1.id, c2.id]
    end

    test "caches active configs on second call" do
      insert(:llm_config, active: true, position: 0)
      _ = OpenRouter.resolve_config()

      # Cache should be populated
      assert Cache.get(:active_llm_configs) != nil
    end

    test "returns empty list when no active configs" do
      insert(:llm_config, active: false)
      assert OpenRouter.resolve_config() == []
    end
  end

  describe "build_body/3" do
    @messages [%{role: "user", content: "Hello"}]
    @prompt "You are a helpful assistant"

    test "uses single model when one active config" do
      configs = [
        build(:llm_config,
          model: "openai/gpt-4o",
          temperature: 0.7,
          max_tokens: 4096
        )
      ]

      body = OpenRouter.build_body(@messages, @prompt, configs)
      decoded = Jason.decode!(body)

      assert decoded["model"] == "openai/gpt-4o"
      refute Map.has_key?(decoded, "models")
      refute Map.has_key?(decoded, "route")
      assert decoded["temperature"] == 0.7
      assert decoded["max_tokens"] == 4096
    end

    test "uses models array with fallback for multiple" do
      configs = [
        build(:llm_config,
          model: "openai/gpt-4o",
          position: 0,
          temperature: 0.5
        ),
        build(:llm_config,
          model: "anthropic/claude-3.5-sonnet",
          position: 1
        )
      ]

      body = OpenRouter.build_body(@messages, @prompt, configs)
      decoded = Jason.decode!(body)

      refute Map.has_key?(decoded, "model")

      assert decoded["models"] == [
               "openai/gpt-4o",
               "anthropic/claude-3.5-sonnet"
             ]

      assert decoded["route"] == "fallback"
      assert decoded["temperature"] == 0.5
    end

    test "falls back to default model when no configs" do
      body = OpenRouter.build_body(@messages, @prompt, [])
      decoded = Jason.decode!(body)

      assert decoded["model"] == "openrouter/free"
      refute Map.has_key?(decoded, "models")
    end

    test "omits nil temperature and max_tokens" do
      configs = [
        build(:llm_config,
          model: "openai/gpt-4o",
          temperature: nil,
          max_tokens: nil
        )
      ]

      body = OpenRouter.build_body(@messages, @prompt, configs)
      decoded = Jason.decode!(body)

      refute Map.has_key?(decoded, "temperature")
      refute Map.has_key?(decoded, "max_tokens")
    end

    test "includes system prompt in messages" do
      body = OpenRouter.build_body(@messages, @prompt, [])
      decoded = Jason.decode!(body)

      [system | rest] = decoded["messages"]
      assert system["role"] == "system"
      assert system["content"] == @prompt
      assert length(rest) == 1
    end
  end
end
