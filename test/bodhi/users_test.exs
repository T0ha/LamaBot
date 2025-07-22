defmodule Bodhi.UsersTest do
  use Bodhi.DataCase

  import Bodhi.Factory

  alias Bodhi.Users

  describe "users" do
    alias Bodhi.Users.User

    test "list_users/0 returns all users" do
      user = insert(:user)
      assert Users.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = insert(:user)

      assert user == Users.get_user!(user.id)
    end

    test "create_user/1 with valid data creates a user" do
      user_params =
        :user
        |> params_for()
        |> Map.put(:id, Faker.random_between(1, 10_000))

      assert {:ok, %User{} = user} = Users.create_user(user_params)
      assert user.username == user_params.username
      assert user.first_name == user_params.first_name
      assert user.last_name == user_params.last_name
      assert user.language_code == user_params.language_code
      assert user.is_admin == user_params.is_admin
    end

    test "create_user/1 with invalid data returns error changeset" do
      user = params_for(:user, %{id: nil})
      assert {:error, %Ecto.Changeset{}} = Users.create_user(user)
    end

    test "update_user/2 with valid data updates the user" do
      user = insert(:user)

      update_attrs = params_for(:user)

      assert {:ok, %User{} = user} = Users.update_user(user, update_attrs)
      assert user.username == update_attrs.username
      assert user.first_name == update_attrs.first_name
      assert user.last_name == update_attrs.last_name
      assert user.language_code == update_attrs.language_code
      assert user.is_admin == update_attrs.is_admin
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = insert(:user)
      update_attrs = %{username: nil}
      assert {:error, %Ecto.Changeset{}} = Users.update_user(user, update_attrs)

      assert user == Users.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = insert(:user)
      assert {:ok, %User{}} = Users.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Users.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = build(:user)
      assert %Ecto.Changeset{} = Users.change_user(user)
    end
  end
end
