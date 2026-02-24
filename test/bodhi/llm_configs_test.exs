defmodule Bodhi.LlmConfigsTest do
  use Bodhi.DataCase, async: false

  alias Bodhi.LlmConfigs
  alias Bodhi.LlmConfigs.LlmConfig
  alias Bodhi.Cache

  setup do
    Cache.delete_all()
    :ok
  end

  describe "list_llm_configs/0" do
    test "returns all configs ordered by position" do
      c2 = insert(:llm_config, position: 2)
      c0 = insert(:llm_config, position: 0)
      c1 = insert(:llm_config, position: 1)

      result = LlmConfigs.list_llm_configs()

      assert Enum.map(result, & &1.id) ==
               [c0.id, c1.id, c2.id]
    end

    test "returns empty list when no configs" do
      assert LlmConfigs.list_llm_configs() == []
    end
  end

  describe "list_llm_configs/1 with filters" do
    test "filters by active: active" do
      active = insert(:llm_config, active: true)
      _inactive = insert(:llm_config, active: false)

      result =
        LlmConfigs.list_llm_configs(%{"active" => "active"})

      assert Enum.map(result, & &1.id) == [active.id]
    end

    test "filters by active: inactive" do
      _active = insert(:llm_config, active: true)
      inactive = insert(:llm_config, active: false)

      result =
        LlmConfigs.list_llm_configs(%{
          "active" => "inactive"
        })

      assert Enum.map(result, & &1.id) == [inactive.id]
    end

    test "active: all returns everything" do
      c1 = insert(:llm_config, active: true, position: 0)
      c2 = insert(:llm_config, active: false, position: 1)

      result =
        LlmConfigs.list_llm_configs(%{"active" => "all"})

      assert Enum.map(result, & &1.id) == [c1.id, c2.id]
    end

    test "filters by search matching name" do
      match =
        insert(:llm_config, name: "GPT-4o", model: "x/y")

      _no_match =
        insert(:llm_config, name: "Claude", model: "a/b")

      result =
        LlmConfigs.list_llm_configs(%{"search" => "gpt"})

      assert Enum.map(result, & &1.id) == [match.id]
    end

    test "filters by search matching model" do
      match =
        insert(:llm_config,
          name: "Foo",
          model: "openai/gpt-4o"
        )

      _no_match =
        insert(:llm_config,
          name: "Bar",
          model: "anthropic/claude"
        )

      result =
        LlmConfigs.list_llm_configs(%{
          "search" => "openai"
        })

      assert Enum.map(result, & &1.id) == [match.id]
    end

    test "empty search returns all" do
      c1 = insert(:llm_config, position: 0)
      c2 = insert(:llm_config, position: 1)

      result =
        LlmConfigs.list_llm_configs(%{"search" => ""})

      assert Enum.map(result, & &1.id) == [c1.id, c2.id]
    end

    test "sorts by name asc" do
      b = insert(:llm_config, name: "Beta", position: 0)
      a = insert(:llm_config, name: "Alpha", position: 1)

      result =
        LlmConfigs.list_llm_configs(%{
          "sort_by" => "name",
          "sort_dir" => "asc"
        })

      assert Enum.map(result, & &1.id) == [a.id, b.id]
    end

    test "sorts by name desc" do
      b = insert(:llm_config, name: "Beta", position: 0)
      a = insert(:llm_config, name: "Alpha", position: 1)

      result =
        LlmConfigs.list_llm_configs(%{
          "sort_by" => "name",
          "sort_dir" => "desc"
        })

      assert Enum.map(result, & &1.id) == [b.id, a.id]
    end

    test "defaults to position asc when no sort" do
      c2 = insert(:llm_config, position: 2)
      c0 = insert(:llm_config, position: 0)

      result = LlmConfigs.list_llm_configs(%{})

      assert Enum.map(result, & &1.id) == [c0.id, c2.id]
    end

    test "falls back to position for invalid sort field" do
      c2 = insert(:llm_config, position: 2)
      c0 = insert(:llm_config, position: 0)

      result =
        LlmConfigs.list_llm_configs(%{
          "sort_by" => "hacked",
          "sort_dir" => "asc"
        })

      assert Enum.map(result, & &1.id) == [c0.id, c2.id]
    end

    test "combines active filter with search" do
      match =
        insert(:llm_config,
          name: "GPT-4o",
          active: true,
          position: 0
        )

      _wrong_status =
        insert(:llm_config,
          name: "GPT-3.5",
          active: false,
          position: 1
        )

      _wrong_name =
        insert(:llm_config,
          name: "Claude",
          active: true,
          position: 2
        )

      result =
        LlmConfigs.list_llm_configs(%{
          "active" => "active",
          "search" => "gpt"
        })

      assert Enum.map(result, & &1.id) == [match.id]
    end

    test "combines filters with sort" do
      b =
        insert(:llm_config,
          name: "Beta-GPT",
          active: true,
          position: 0
        )

      a =
        insert(:llm_config,
          name: "Alpha-GPT",
          active: true,
          position: 1
        )

      _inactive =
        insert(:llm_config,
          name: "CGPT",
          active: false,
          position: 2
        )

      result =
        LlmConfigs.list_llm_configs(%{
          "active" => "active",
          "search" => "gpt",
          "sort_by" => "name",
          "sort_dir" => "asc"
        })

      assert Enum.map(result, & &1.id) == [a.id, b.id]
    end
  end

  describe "get_llm_config!/1" do
    test "returns the config with given id" do
      config = insert(:llm_config)
      assert LlmConfigs.get_llm_config!(config.id).id == config.id
    end

    test "raises when config not found" do
      assert_raise Ecto.NoResultsError, fn ->
        LlmConfigs.get_llm_config!(0)
      end
    end
  end

  describe "get_active_configs/0" do
    test "returns only active configs ordered by position" do
      insert(:llm_config, active: false, position: 0)
      a1 = insert(:llm_config, active: true, position: 2)
      a0 = insert(:llm_config, active: true, position: 1)

      result = LlmConfigs.get_active_configs()

      assert length(result) == 2
      assert Enum.map(result, & &1.id) == [a0.id, a1.id]
    end

    test "returns empty list when no active configs" do
      insert(:llm_config, active: false)
      assert LlmConfigs.get_active_configs() == []
    end
  end

  describe "create_llm_config/1" do
    test "with valid data creates a config" do
      attrs = params_for(:llm_config, name: "new-config")

      assert {:ok, %LlmConfig{} = config} =
               LlmConfigs.create_llm_config(attrs)

      assert config.name == "new-config"
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               LlmConfigs.create_llm_config(%{})
    end

    test "enforces unique name constraint" do
      insert(:llm_config, name: "unique")

      assert {:error, changeset} =
               LlmConfigs.create_llm_config(params_for(:llm_config, name: "unique"))

      assert %{name: ["has already been taken"]} =
               errors_on(changeset)
    end

    test "invalidates cache when creating active config" do
      Cache.put(:active_llm_configs, [])

      attrs =
        params_for(:llm_config, active: true, name: "cached")

      {:ok, _} = LlmConfigs.create_llm_config(attrs)

      assert Cache.get(:active_llm_configs) == nil
    end

    test "does not invalidate cache for inactive config" do
      Cache.put(:active_llm_configs, [])

      attrs = params_for(:llm_config, active: false)
      {:ok, _} = LlmConfigs.create_llm_config(attrs)

      assert Cache.get(:active_llm_configs) == []
    end
  end

  describe "update_llm_config/2" do
    test "with valid data updates the config" do
      config = insert(:llm_config)

      assert {:ok, %LlmConfig{} = updated} =
               LlmConfigs.update_llm_config(config, %{
                 temperature: 0.5
               })

      assert updated.temperature == 0.5
    end

    test "with invalid data returns error changeset" do
      config = insert(:llm_config)

      assert {:error, %Ecto.Changeset{}} =
               LlmConfigs.update_llm_config(config, %{
                 name: nil
               })
    end

    test "invalidates cache when toggling active" do
      config = insert(:llm_config, active: false)
      Cache.put(:active_llm_configs, [])

      {:ok, _} =
        LlmConfigs.update_llm_config(config, %{active: true})

      assert Cache.get(:active_llm_configs) == nil
    end

    test "invalidates cache when updating active config" do
      config = insert(:llm_config, active: true)
      Cache.put(:active_llm_configs, [config])

      {:ok, _} =
        LlmConfigs.update_llm_config(config, %{model: "new/model"})

      assert Cache.get(:active_llm_configs) == nil
    end
  end

  describe "delete_llm_config/1" do
    test "deletes the config" do
      config = insert(:llm_config)

      assert {:ok, %LlmConfig{}} =
               LlmConfigs.delete_llm_config(config)

      assert_raise Ecto.NoResultsError, fn ->
        LlmConfigs.get_llm_config!(config.id)
      end
    end

    test "invalidates cache when deleting active config" do
      config = insert(:llm_config, active: true)
      Cache.put(:active_llm_configs, [config])

      {:ok, _} = LlmConfigs.delete_llm_config(config)

      assert Cache.get(:active_llm_configs) == nil
    end
  end

  describe "sync_models/1" do
    test "creates new configs for unknown models" do
      remote = [
        %{"id" => "openai/gpt-4o", "name" => "GPT-4o"},
        %{
          "id" => "anthropic/claude-3.5-sonnet",
          "name" => "Claude 3.5 Sonnet"
        }
      ]

      assert {:ok, %{created: 2, deactivated: 0}} =
               LlmConfigs.sync_models(remote)

      configs = LlmConfigs.list_llm_configs()
      assert length(configs) == 2

      assert Enum.all?(configs, &(!&1.active))

      models = Enum.map(configs, & &1.model) |> Enum.sort()

      assert models == [
               "anthropic/claude-3.5-sonnet",
               "openai/gpt-4o"
             ]
    end

    test "does not modify existing configs" do
      existing =
        insert(:llm_config,
          model: "openai/gpt-4o",
          name: "My GPT",
          active: true,
          temperature: 0.7
        )

      remote = [
        %{"id" => "openai/gpt-4o", "name" => "GPT-4o"}
      ]

      assert {:ok, %{created: 0, deactivated: 0}} =
               LlmConfigs.sync_models(remote)

      reloaded =
        LlmConfigs.get_llm_config!(existing.id)

      assert reloaded.name == "My GPT"
      assert reloaded.active == true
      assert reloaded.temperature == 0.7
    end

    test "deactivates stale configs not in remote" do
      stale =
        insert(:llm_config,
          model: "old/model",
          active: true
        )

      kept =
        insert(:llm_config,
          model: "openai/gpt-4o",
          active: true
        )

      remote = [
        %{"id" => "openai/gpt-4o", "name" => "GPT-4o"}
      ]

      assert {:ok, %{created: 0, deactivated: 1}} =
               LlmConfigs.sync_models(remote)

      assert LlmConfigs.get_llm_config!(stale.id).active ==
               false

      assert LlmConfigs.get_llm_config!(kept.id).active ==
               true
    end

    test "handles name collision by falling back to model id" do
      insert(:llm_config,
        name: "GPT-4o",
        model: "other/model"
      )

      remote = [
        %{"id" => "openai/gpt-4o", "name" => "GPT-4o"}
      ]

      assert {:ok, %{created: 1, deactivated: 0}} =
               LlmConfigs.sync_models(remote)

      new_config =
        Repo.get_by!(LlmConfig, model: "openai/gpt-4o")

      assert new_config.name == "openai/gpt-4o"
    end

    test "invalidates cache after sync" do
      Cache.put(:active_llm_configs, [])

      remote = [
        %{"id" => "openai/gpt-4o", "name" => "GPT-4o"}
      ]

      {:ok, _} = LlmConfigs.sync_models(remote)

      assert Cache.get(:active_llm_configs) == nil
    end

    test "handles empty remote list by deactivating all" do
      insert(:llm_config, active: true)
      insert(:llm_config, active: true)

      assert {:ok, %{created: 0, deactivated: 2}} =
               LlmConfigs.sync_models([])
    end
  end

  describe "change_llm_config/2" do
    test "returns a changeset" do
      config = insert(:llm_config)

      assert %Ecto.Changeset{} =
               LlmConfigs.change_llm_config(config)
    end
  end
end
