defmodule BodhiWeb.PromptLiveTest do
  use BodhiWeb.ConnCase

  import Phoenix.LiveViewTest

  @invalid_attrs %{text: nil, type: nil, lang: nil}

  defp create_prompt(_) do
    prompt = insert(:prompt, lang: "en")
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

  describe "Index" do
    setup [:create_prompt, :create_and_log_in_user]

    test "lists all prompts", %{
      conn: conn,
      prompt: prompt
    } do
      {:ok, _live, html} = live(conn, ~p"/prompts")

      assert html =~ "Listing Prompts"
      assert html =~ prompt.text
    end

    test "deletes prompt in listing", %{
      conn: conn,
      prompt: prompt
    } do
      {:ok, live, _html} = live(conn, ~p"/prompts")

      assert live
             |> element(
               "#prompts-#{prompt.id} a",
               "Delete"
             )
             |> render_click()

      refute has_element?(
               live,
               "#prompts-#{prompt.id}"
             )
    end
  end

  describe "Form - new" do
    setup [:create_and_log_in_user]

    test "creates new prompt with valid data", %{
      conn: conn
    } do
      {:ok, live, _html} = live(conn, ~p"/prompts/new")

      assert live
             |> form("#prompt-form",
               prompt: @invalid_attrs
             )
             |> render_change() =~ "can&#39;t be blank"

      create_attrs = %{
        text: "Test prompt text",
        type: :context,
        lang: "en",
        active: true
      }

      assert {:ok, index_live, _html} =
               live
               |> form("#prompt-form",
                 prompt: create_attrs
               )
               |> render_submit()
               |> follow_redirect(conn, ~p"/prompts")

      html = render(index_live)
      assert html =~ "Prompt created successfully"
      assert html =~ "Test prompt text"
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
        type: :followup,
        lang: "uk"
      }

      assert {:ok, index_live, _html} =
               live
               |> form("#prompt-form",
                 prompt: update_attrs
               )
               |> render_submit()
               |> follow_redirect(conn, ~p"/prompts")

      html = render(index_live)
      assert html =~ "Prompt updated successfully"
      assert html =~ "Updated prompt text"
    end
  end

  describe "Navigation" do
    setup [:create_prompt, :create_and_log_in_user]

    test "navigates from index to new form", %{
      conn: conn
    } do
      {:ok, index_live, _html} = live(conn, ~p"/prompts")

      assert {:ok, _form_live, html} =
               index_live
               |> element("a", "New Prompt")
               |> render_click()
               |> follow_redirect(conn, ~p"/prompts/new")

      assert html =~ "New Prompt"
    end

    test "navigates from index to edit form", %{
      conn: conn,
      prompt: prompt
    } do
      {:ok, index_live, _html} = live(conn, ~p"/prompts")

      assert {:ok, _form_live, html} =
               index_live
               |> element(
                 "#prompts-#{prompt.id} a",
                 "Edit"
               )
               |> render_click()
               |> follow_redirect(
                 conn,
                 ~p"/prompts/#{prompt.id}/edit"
               )

      assert html =~ "Edit Prompt"
    end
  end

  describe "auth required" do
    test "redirects unauthenticated user", %{
      conn: conn
    } do
      assert {:error, {:redirect, %{to: "/"}}} =
               live(conn, ~p"/prompts")
    end
  end
end
