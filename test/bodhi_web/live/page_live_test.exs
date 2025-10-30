defmodule BodhiWeb.PageLiveTest do
  use BodhiWeb.ConnCase

  import Phoenix.LiveViewTest

  @invalid_attrs %{format: nil, header: false, description: nil, slug: nil, content: nil}

  defp create_page(_) do
    page = insert(:page)

    %{page: page}
  end

  defp create_and_log_in_user(%{conn: conn}) do
    user = insert(:user, is_admin: true)
    token = Phoenix.Token.sign(BodhiWeb.Endpoint, "user auth", user.id)
    conn = 
      Plug.Test.init_test_session(conn, %{"token" => token})
    {:ok, conn: conn, user: user}
  end

  describe "Index" do
    setup [:create_page, :create_and_log_in_user]

    test "lists all pages", %{conn: conn, page: page} do
      {:ok, _index_live, html} = live(conn, ~p"/pages")

      assert html =~ "Listing Pages"
      assert html =~ page.slug
    end

    test "saves new page", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/pages")
      create_attrs = params_for(:page)

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Page")
               |> render_click()
               |> follow_redirect(conn, ~p"/pages/new")

      assert render(form_live) =~ "New Page"

      assert form_live
             |> form("#page-form", page: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#page-form", page: create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/pages")

      html = render(index_live)
      assert html =~ "Page created successfully"
      assert html =~ create_attrs.content
    end

    test "updates page in listing", %{conn: conn, page: page} do
      {:ok, index_live, _html} = live(conn, ~p"/pages")
      update_attrs = params_for(:page)

      assert {:ok, form_live, _html} =
               index_live
               |> element("#pages-#{page.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/pages/#{page}/edit")

      assert render(form_live) =~ "Edit Page"

      assert form_live
             |> form("#page-form", page: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#page-form", page: update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/pages")

      html = render(index_live)
      assert html =~ "Page updated successfully"
      assert html =~ update_attrs.content
    end

    test "deletes page in listing", %{conn: conn, page: page} do
      {:ok, index_live, _html} = live(conn, ~p"/pages")

      assert index_live |> element("#pages-#{page.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#pages-#{page.id}")
    end
  end

  describe "Show" do
    setup [:create_page, :create_and_log_in_user]

    test "displays page", %{conn: conn, page: page} do
      {:ok, _show_live, html} = live(conn, ~p"/pages/#{page}")

      assert html =~ "Show Page"
      assert html =~ page.slug
    end

    test "updates page and returns to show", %{conn: conn, page: page} do
      {:ok, show_live, _html} = live(conn, ~p"/pages/#{page}")
      update_attrs = params_for(:page)

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/pages/#{page}/edit?return_to=show")

      assert render(form_live) =~ "Edit Page"

      assert form_live
             |> form("#page-form", page: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#page-form", page: update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/pages/#{page}")

      html = render(show_live)
      assert html =~ "Page updated successfully"
      assert html =~ update_attrs.content
    end
  end
end
