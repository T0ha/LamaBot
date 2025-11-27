defmodule Bodhi.Pages.Page do
  @moduledoc """
  Schema for managing CMS pages with support for multiple content formats.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "pages" do
    field :slug, :string
    field :header, :boolean, default: false
    field :title, :string
    field :description, :string
    field :template, :string, default: "page"
    field :format, Ecto.Enum, values: [:markdown, :html, :text, :eex]
    field :content, :string

    timestamps()
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:slug, :header, :title, :description, :format, :content, :template])
    |> validate_required([:slug, :header, :title, :description, :format, :content])
    |> unique_constraint(:slug)
  end
end
