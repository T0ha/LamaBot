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

      assert {:ok, %Prompt{} = prompt} = Prompts.create_prompt(prompt_params)
      assert prompt.text == prompt_params.text
      assert prompt.type == prompt_params.type
      assert prompt.lang == prompt_params.lang
      assert prompt.active == prompt_params.active
    end

    test "create_prompt/1 with invalid data returns error changeset" do
      prompt = params_for(:prompt, %{type: nil})
      assert {:error, %Ecto.Changeset{}} = Prompts.create_prompt(prompt)
    end

    test "update_prompt/2 with valid data updates the prompt" do
      prompt = insert(:prompt)

      update_attrs = params_for(:prompt)

      assert {:ok, %Prompt{} = prompt} = Prompts.update_prompt(prompt, update_attrs)
      assert prompt.text == update_attrs.text
      assert prompt.type == update_attrs.type
      assert prompt.lang == update_attrs.lang
      assert prompt.active == update_attrs.active
    end

    test "update_prompt/2 with invalid data returns error changeset" do
      prompt = insert(:prompt)
      update_attrs = %{type: nil}
      assert {:error, %Ecto.Changeset{}} = Prompts.update_prompt(prompt, update_attrs)

      assert prompt == Prompts.get_prompt!(prompt.id)
    end

    test "delete_prompt/1 deletes the prompt" do
      prompt = insert(:prompt)
      assert {:ok, %Prompt{}} = Prompts.delete_prompt(prompt)
      assert_raise Ecto.NoResultsError, fn -> Prompts.get_prompt!(prompt.id) end
    end

    test "change_prompt/1 returns a prompt changeset" do
      prompt = build(:prompt)
      assert %Ecto.Changeset{} = Prompts.change_prompt(prompt)
    end
  end
end
