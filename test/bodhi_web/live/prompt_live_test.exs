defmodule BodhiWeb.PromptLiveTest do
  use BodhiWeb.ConnCase

  import Phoenix.LiveViewTest

  @invalid_attrs %{text: nil, type: nil, lang: nil}

  defp create_prompt(_) do
    prompt = insert(:prompt, type: :context, lang: "en")
    %{prompt: prompt}
  end

  defp create_and_log_in_user(%{conn: conn}) do
    user = insert(:user, is_admin: true)

    token =
      Phoenix.Token.sign(
        BodhiWeb.Endpoint,
        "user auth",
        user.id
      )

    conn =
      Plug.Test.init_test_session(conn, %{"token" => token})

    {:ok, conn: conn, user: user}
  end

  describe "Show" do
    setup [:create_prompt, :create_and_log_in_user]

    test "displays the context prompt", %{
      conn: conn,
      prompt: prompt
    } do
      {:ok, _live, html} = live(conn, ~p"/prompts")

      assert html =~ "Context Prompt"
      assert html =~ prompt.text
      assert html =~ to_string(prompt.type)
      assert html =~ prompt.lang
    end

    test "has edit button", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/prompts")

      assert has_element?(live, "a", "Edit")
    end
  end

  describe "Form - edit" do
    setup [:create_prompt, :create_and_log_in_user]

    test "updates prompt with valid data", %{
      conn: conn,
      prompt: prompt
    } do
      {:ok, live, _html} =
        live(conn, ~p"/prompts/#{prompt.id}/edit")

      assert live
             |> form("#prompt-form",
               prompt: @invalid_attrs
             )
             |> render_change() =~ "can&#39;t be blank"

      update_attrs = %{
        text: "Updated prompt text",
        type: :context,
        lang: "uk"
      }

      assert {:ok, show_live, _html} =
               live
               |> form("#prompt-form",
                 prompt: update_attrs
               )
               |> render_submit()
               |> follow_redirect(conn, ~p"/prompts")

      html = render(show_live)
      assert html =~ "Prompt updated successfully"
      assert html =~ "Updated prompt text"
    end
  end

  describe "Navigation" do
    setup [:create_prompt, :create_and_log_in_user]

    test "navigates from show to edit form", %{
      conn: conn,
      prompt: prompt
    } do
      {:ok, show_live, _html} = live(conn, ~p"/prompts")

      assert {:ok, _form_live, html} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(
                 conn,
                 ~p"/prompts/#{prompt.id}/edit"
               )

      assert html =~ "Edit Prompt"
    end
  end

  describe "Show - auto-create" do
    setup [:create_and_log_in_user]

    test "creates default prompt when none exists", %{
      conn: conn
    } do
      {:ok, live, html} = live(conn, ~p"/prompts")

      assert html =~ "Context Prompt"
      assert html =~ "context"
      assert has_element?(live, "a", "Edit")
    end
  end

  describe "auth required" do
    setup [:create_prompt]

    test "redirects unauthenticated user from show", %{
      conn: conn
    } do
      assert {:error, {:redirect, %{to: "/"}}} =
               live(conn, ~p"/prompts")
    end

    test "redirects unauthenticated user from edit", %{
      conn: conn,
      prompt: prompt
    } do
      assert {:error, {:redirect, %{to: "/"}}} =
               live(conn, ~p"/prompts/#{prompt.id}/edit")
    end
  end
end
