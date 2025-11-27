defmodule Bodhi.PagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Bodhi.Pages` context.
  """

  @doc """
  Generate a unique page slug.
  """
  def unique_page_slug, do: "some slug#{System.unique_integer([:positive])}"

  @doc """
  Generate a page.
  """
  def page_fixture(attrs \\ %{}) do
    {:ok, page} =
      attrs
      |> Enum.into(%{
        content: "some content",
        description: "some description",
        format: :markdowm,
        header: true,
        slug: unique_page_slug()
      })
      |> Bodhi.Pages.create_page()

    page
  end
end
