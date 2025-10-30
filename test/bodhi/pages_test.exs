defmodule Bodhi.PagesTest do
  use Bodhi.DataCase

  alias Bodhi.Pages

  describe "pages" do
    alias Bodhi.Pages.Page

    @invalid_attrs %{format: nil, header: nil, description: nil, slug: nil, content: nil}

    test "list_pages/0 returns all pages" do
      page = insert(:page)
      assert Pages.list_pages() == [page]
    end

    test "get_page!/1 returns the page with given id" do
      page = insert(:page)
      assert Pages.get_page!(page.id) == page
    end

    test "create_page/1 with valid data creates a page" do
      valid_attrs = params_for(:page)

      assert {:ok, %Page{} = page} = Pages.create_page(valid_attrs)
      assert page.format == valid_attrs.format
      assert page.header == valid_attrs.header
      assert page.description == valid_attrs.description
      assert page.slug == valid_attrs.slug
      assert page.content == valid_attrs.content
    end

    test "create_page/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Pages.create_page(@invalid_attrs)
    end

    test "update_page/2 with valid data updates the page" do
      page = insert(:page)

      update_attrs = params_for(:page)

      assert {:ok, %Page{} = page} = Pages.update_page(page, update_attrs)
      assert page.format == update_attrs.format
      assert page.header == update_attrs.header
      assert page.description == update_attrs.description
      assert page.slug == update_attrs.slug
      assert page.content == update_attrs.content
    end

    test "update_page/2 with invalid data returns error changeset" do
      page = insert(:page)
      assert {:error, %Ecto.Changeset{}} = Pages.update_page(page, @invalid_attrs)
      assert page == Pages.get_page!(page.id)
    end

    test "delete_page/1 deletes the page" do
      page = insert(:page)
      assert {:ok, %Page{}} = Pages.delete_page(page)
      assert_raise Ecto.NoResultsError, fn -> Pages.get_page!(page.id) end
    end

    test "change_page/1 returns a page changeset" do
      page = insert(:page)
      assert %Ecto.Changeset{} = Pages.change_page(page)
    end
  end
end
