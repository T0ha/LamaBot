defmodule BodhiWeb.PageControllerTest do
  use BodhiWeb.ConnCase

  test "GET /", %{conn: conn} do
    index = insert(:page, slug: "index", template: "index", content: "")
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Talk to Lama Bot"
    assert html_response(conn, 200) =~ index.content
  end

  describe "GET /p/:slug" do
    @markdown """
    # Title
    This is a **bold** statement.
    - Item 1
    - Item 200
    """

    @html """
    <h1>Title</h1>
    This is a <strong>bold</strong> statement.
    <ul>
      <li>Item 1</li>
      <li>Item 200</li>
    </ul>
    """

      @eex """
    <h1>Title</h1>
    This is a <strong>bold</strong> statement.
      <%= @page.slug %>
    <ul>
      <li>Item 1</li>
      <li>Item 200</li>
    </ul>
    """

    test "Plain text", %{conn: conn} do
      page = insert(:page, format: :text)
      conn = get(conn, ~p"/p/#{page.slug}")
      assert html_response(conn, 200) =~ page.title
      assert html_response(conn, 200) =~ page.description
      assert html_response(conn, 200) =~ page.content
      refute html_response(conn, 200) =~ page.slug
    end

    test "Markdown", %{conn: conn} do
      page = insert(:page, format: :markdown, content: @markdown)
      conn = get(conn, ~p"/p/#{page.slug}")
      assert html_response(conn, 200) =~ page.title
      assert html_response(conn, 200) =~ page.description
      refute html_response(conn, 200) =~ page.content
      refute html_response(conn, 200) =~ page.slug

      assert html_response(conn, 200) =~ "<h1>Title</h1>"
      assert html_response(conn, 200) =~ "<strong>bold</strong>"
      assert html_response(conn, 200) =~ "<li>Item 1</li>"
      assert html_response(conn, 200) =~ "<li>Item 200</li>"
    end

    test "HTML", %{conn: conn} do
      page = insert(:page, format: :html, content: @html)
      conn = get(conn, ~p"/p/#{page.slug}")
      assert html_response(conn, 200) =~ page.title
      assert html_response(conn, 200) =~ page.description
      assert html_response(conn, 200) =~ page.content
      refute html_response(conn, 200) =~ page.slug

      assert html_response(conn, 200) =~ "<h1>Title</h1>"
      assert html_response(conn, 200) =~ "<strong>bold</strong>"
      assert html_response(conn, 200) =~ "<li>Item 1</li>"
      assert html_response(conn, 200) =~ "<li>Item 200</li>"
    end

    test "EEX", %{conn: conn} do
      page = insert(:page, format: :eex, content: @eex)
      conn = get(conn, ~p"/p/#{page.slug}")
      assert html_response(conn, 200) =~ page.title
      assert html_response(conn, 200) =~ page.description
      refute html_response(conn, 200) =~ page.content

      assert html_response(conn, 200) =~ "<h1>Title</h1>"
      assert html_response(conn, 200) =~ "<strong>bold</strong>"
      assert html_response(conn, 200) =~ "<li>Item 1</li>"
      assert html_response(conn, 200) =~ "<li>Item 200</li>"
      assert html_response(conn, 200) =~ page.slug
    end
  end
end
