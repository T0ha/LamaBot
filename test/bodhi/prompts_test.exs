defmodule Bodhi.AccountsTest do
  use Bodhi.DataCase

  import Bodhi.Factory

  alias Bodhi.Prompts

  describe "prompts" do
    alias Bodhi.Prompts.Prompt

    test "list_prompts/0 returns all prompts" do
      prompt = insert(:prompt)
      assert Prompts.list_prompts() == [prompt]
    end

    test "get_prompt!/1 returns the prompt with given id" do
      prompt = insert(:prompt)

      assert prompt == Prompts.get_prompt!(prompt.id)
    end

    test "create_prompt/1 with valid data creates a prompt" do
      prompt_params = params_for(:prompt)

      assert {:ok, %Prompt{} = prompt} =
               Prompts.create_prompt(prompt_params)

      assert prompt.text == prompt_params.text
      assert prompt.type == prompt_params.type
      assert prompt.lang == prompt_params.lang
      assert prompt.active == prompt_params.active
    end

    test "create_prompt/1 with invalid data returns error changeset" do
      prompt = params_for(:prompt, %{type: nil})

      assert {:error, %Ecto.Changeset{}} =
               Prompts.create_prompt(prompt)
    end

    test "update_prompt/2 with valid data updates the prompt" do
      prompt = insert(:prompt)

      update_attrs = params_for(:prompt)

      assert {:ok, %Prompt{} = prompt} =
               Prompts.update_prompt(prompt, update_attrs)

      assert prompt.text == update_attrs.text
      assert prompt.type == update_attrs.type
      assert prompt.lang == update_attrs.lang
      assert prompt.active == update_attrs.active
    end

    test "update_prompt/2 with invalid data returns error changeset" do
      prompt = insert(:prompt)
      update_attrs = %{type: nil}

      assert {:error, %Ecto.Changeset{}} =
               Prompts.update_prompt(prompt, update_attrs)

      assert prompt == Prompts.get_prompt!(prompt.id)
    end

    test "delete_prompt/1 deletes the prompt" do
      prompt = insert(:prompt)

      assert {:ok, %Prompt{}} =
               Prompts.delete_prompt(prompt)

      assert_raise Ecto.NoResultsError, fn ->
        Prompts.get_prompt!(prompt.id)
      end
    end

    test "change_prompt/1 returns a prompt changeset" do
      prompt = build(:prompt)
      assert %Ecto.Changeset{} = Prompts.change_prompt(prompt)
    end
  end

  describe "prompt versioning" do
    alias Bodhi.Prompts.PromptVersion

    test "update creates a history entry" do
      prompt = insert(:prompt, type: :context, text: "v1 text")

      {:ok, updated} =
        Prompts.update_prompt(prompt, %{text: "v2 text"})

      assert updated.version == 2

      versions = Prompts.list_prompt_versions(prompt.id)
      assert length(versions) == 1

      [v1] = versions
      assert v1.version == 1
      assert v1.text == "v1 text"
    end

    test "list_prompt_versions/1 returns versions ordered by version desc" do
      prompt = insert(:prompt, type: :context, text: "v1")

      {:ok, _} = Prompts.update_prompt(prompt, %{text: "v2"})

      prompt = Prompts.get_prompt!(prompt.id)

      {:ok, _} = Prompts.update_prompt(prompt, %{text: "v3"})

      versions = Prompts.list_prompt_versions(prompt.id)
      version_numbers = Enum.map(versions, & &1.version)
      assert version_numbers == [2, 1]
    end

    test "get_prompt_version!/2 returns specific version" do
      prompt = insert(:prompt, type: :context, text: "v1")

      {:ok, _} = Prompts.update_prompt(prompt, %{text: "v2"})

      %PromptVersion{} =
        v1 =
        Prompts.get_prompt_version!(prompt.id, 1)

      assert v1.text == "v1"
      assert v1.version == 1
      refute is_nil(v1.valid_from)
    end

    test "restore_prompt_version/3 is append-only" do
      user = insert(:user)
      prompt = insert(:prompt, type: :context, text: "v1")

      {:ok, _} = Prompts.update_prompt(prompt, %{text: "v2"})

      prompt = Prompts.get_prompt!(prompt.id)
      assert prompt.version == 2

      {:ok, restored} =
        Prompts.restore_prompt_version(prompt, 1, user.id)

      assert restored.text == "v1"
      assert restored.version == 3
      assert restored.changed_by == user.id

      versions = Prompts.list_prompt_versions(prompt.id)
      assert length(versions) == 2
    end

    test "unchanged update skips history" do
      prompt = insert(:prompt, type: :context, text: "same")

      {:ok, same} =
        Prompts.update_prompt(prompt, %{text: "same"})

      assert same.version == prompt.version

      versions = Prompts.list_prompt_versions(prompt.id)
      assert versions == []
    end
  end
end
