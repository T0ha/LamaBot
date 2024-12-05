defmodule Bodhi.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  @allowed_attrs ~w(id first_name last_name username language_code is_admin)a
  @required_attrs ~w(id username)a

  schema "users" do
    field :first_name, :string
    field :language_code, :string
    field :last_name, :string
    field :username, :string
    field :is_admin, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(message, %Telegex.Type.User{} = data),
    do:
      data
      |> Map.from_struct()
      |> then(&changeset(message, &1))

  def changeset(user, attrs) do
    user
    |> cast(attrs, @allowed_attrs)
    |> validate_required(@required_attrs)
  end
end
