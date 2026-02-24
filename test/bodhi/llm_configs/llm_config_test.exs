defmodule Bodhi.LlmConfigs.LlmConfigTest do
  use Bodhi.DataCase, async: true

  alias Bodhi.LlmConfigs.LlmConfig

  describe "changeset/2" do
    test "valid changeset with required fields" do
      attrs = %{
        name: "primary",
        model: "openai/gpt-4o",
        position: 0
      }

      changeset = LlmConfig.changeset(%LlmConfig{}, attrs)

      assert changeset.valid?
    end

    test "valid changeset with all fields" do
      attrs = %{
        name: "primary",
        model: "openai/gpt-4o",
        position: 0,
        temperature: 0.7,
        max_tokens: 4096,
        active: true
      }

      changeset = LlmConfig.changeset(%LlmConfig{}, attrs)

      assert changeset.valid?
    end

    test "invalid without name" do
      attrs = %{model: "openai/gpt-4o", position: 0}
      changeset = LlmConfig.changeset(%LlmConfig{}, attrs)

      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid without model" do
      attrs = %{name: "primary", position: 0}
      changeset = LlmConfig.changeset(%LlmConfig{}, attrs)

      refute changeset.valid?
      assert %{model: ["can't be blank"]} = errors_on(changeset)
    end

    test "position is required" do
      attrs = %{name: "primary", model: "openai/gpt-4o", position: nil}

      changeset = LlmConfig.changeset(%LlmConfig{}, attrs)

      refute changeset.valid?
      assert %{position: ["can't be blank"]} = errors_on(changeset)
    end

    test "temperature must be between 0.0 and 2.0" do
      base = %{name: "t", model: "m", position: 0}

      too_low =
        LlmConfig.changeset(
          %LlmConfig{},
          Map.put(base, :temperature, -0.1)
        )

      assert %{temperature: [_]} = errors_on(too_low)

      too_high =
        LlmConfig.changeset(
          %LlmConfig{},
          Map.put(base, :temperature, 2.1)
        )

      assert %{temperature: [_]} = errors_on(too_high)

      at_min =
        LlmConfig.changeset(
          %LlmConfig{},
          Map.put(base, :temperature, 0.0)
        )

      assert at_min.valid?

      at_max =
        LlmConfig.changeset(
          %LlmConfig{},
          Map.put(base, :temperature, 2.0)
        )

      assert at_max.valid?
    end

    test "max_tokens must be between 1 and 128_000" do
      base = %{name: "t", model: "m", position: 0}

      too_low =
        LlmConfig.changeset(
          %LlmConfig{},
          Map.put(base, :max_tokens, 0)
        )

      assert %{max_tokens: [_]} = errors_on(too_low)

      too_high =
        LlmConfig.changeset(
          %LlmConfig{},
          Map.put(base, :max_tokens, 128_001)
        )

      assert %{max_tokens: [_]} = errors_on(too_high)

      valid =
        LlmConfig.changeset(
          %LlmConfig{},
          Map.put(base, :max_tokens, 4096)
        )

      assert valid.valid?
    end

    test "defaults active to false" do
      attrs = %{name: "t", model: "m", position: 0}
      changeset = LlmConfig.changeset(%LlmConfig{}, attrs)

      assert Ecto.Changeset.get_field(changeset, :active) == false
    end

    test "defaults position to 0" do
      config = %LlmConfig{}

      assert config.position == 0
    end
  end
end
