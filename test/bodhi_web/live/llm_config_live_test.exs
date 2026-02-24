defmodule BodhiWeb.LlmConfigLiveTest do
  use BodhiWeb.ConnCase

  import Mox
  import Phoenix.LiveViewTest

  alias Bodhi.Cache

  @invalid_attrs %{name: nil, model: nil, position: nil}

  defp create_llm_config(_) do
    config = insert(:llm_config, active: true)
    %{llm_config: config}
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

  setup do
    Cache.delete_all()
    :ok
  end

  describe "Index" do
    setup [:create_llm_config, :create_and_log_in_user]

    test "lists all llm configs", %{
      conn: conn,
      llm_config: config
    } do
      {:ok, _live, html} = live(conn, ~p"/llm-configs")

      assert html =~ "LLM Configurations"
      assert html =~ config.name
      assert html =~ config.model
    end

    test "deletes config in listing", %{
      conn: conn,
      llm_config: config
    } do
      {:ok, live, _html} = live(conn, ~p"/llm-configs")

      assert live
             |> element(
               "#llm_configs-#{config.id} a",
               "Delete"
             )
             |> render_click()

      refute has_element?(
               live,
               "#llm_configs-#{config.id}"
             )
    end

    test "toggles active status", %{
      conn: conn,
      llm_config: config
    } do
      {:ok, live, _html} = live(conn, ~p"/llm-configs")

      assert live
             |> element(
               "#llm_configs-#{config.id} a",
               "Deactivate"
             )
             |> render_click()

      html = render(live)
      assert html =~ "Activate"
    end
  end

  describe "Filtering and sorting" do
    setup [:create_and_log_in_user]

    setup do
      active =
        insert(:llm_config,
          name: "Alpha-GPT",
          model: "openai/gpt-4o",
          active: true,
          position: 0
        )

      inactive =
        insert(:llm_config,
          name: "Beta-Claude",
          model: "anthropic/claude-3",
          active: false,
          position: 1
        )

      %{active_cfg: active, inactive_cfg: inactive}
    end

    test "text search filters table rows", %{
      conn: conn,
      active_cfg: active,
      inactive_cfg: inactive
    } do
      {:ok, live, html} = live(conn, ~p"/llm-configs")

      assert html =~ active.name
      assert html =~ inactive.name

      html =
        live
        |> form("#filter-form", %{search: "gpt"})
        |> render_change()

      assert html =~ active.name
      refute html =~ inactive.name
    end

    test "active dropdown filters rows", %{
      conn: conn,
      active_cfg: active,
      inactive_cfg: inactive
    } do
      {:ok, live, _html} = live(conn, ~p"/llm-configs")

      html =
        live
        |> form("#filter-form", %{active: "active"})
        |> render_change()

      assert html =~ active.name
      refute html =~ inactive.name

      html =
        live
        |> form("#filter-form", %{active: "inactive"})
        |> render_change()

      refute html =~ active.name
      assert html =~ inactive.name
    end

    test "clicking column header sorts by that column",
         %{conn: conn, active_cfg: active, inactive_cfg: inactive} do
      {:ok, live, _html} = live(conn, ~p"/llm-configs")

      html =
        live
        |> element("th[phx-value-field=name]")
        |> render_click()

      # Alpha before Beta in asc
      alpha_pos = :binary.match(html, active.name)
      beta_pos = :binary.match(html, inactive.name)
      assert elem(alpha_pos, 0) < elem(beta_pos, 0)
    end

    test "clicking same header reverses direction",
         %{conn: conn, active_cfg: active, inactive_cfg: inactive} do
      {:ok, live, _html} = live(conn, ~p"/llm-configs")

      # First click: name asc
      live
      |> element("th[phx-value-field=name]")
      |> render_click()

      # Second click: name desc
      html =
        live
        |> element("th[phx-value-field=name]")
        |> render_click()

      # Beta before Alpha in desc
      alpha_pos = :binary.match(html, active.name)
      beta_pos = :binary.match(html, inactive.name)
      assert elem(beta_pos, 0) < elem(alpha_pos, 0)
    end

    test "filters persist across sort changes", %{
      conn: conn,
      active_cfg: active,
      inactive_cfg: inactive
    } do
      {:ok, live, _html} = live(conn, ~p"/llm-configs")

      # Filter to active only
      live
      |> form("#filter-form", %{active: "active"})
      |> render_change()

      # Now sort by name
      html =
        live
        |> element("th[phx-value-field=name]")
        |> render_click()

      assert html =~ active.name
      refute html =~ inactive.name
    end
  end

  describe "Form - new" do
    setup [:create_and_log_in_user]

    test "creates new config with valid data", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/llm-configs/new")

      assert live
             |> form("#llm-config-form", llm_config: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      create_attrs = %{
        name: "test-config",
        model: "openai/gpt-4o",
        position: 0,
        active: true
      }

      assert {:ok, index_live, _html} =
               live
               |> form("#llm-config-form",
                 llm_config: create_attrs
               )
               |> render_submit()
               |> follow_redirect(conn, ~p"/llm-configs")

      html = render(index_live)
      assert html =~ "LLM config created successfully"
      assert html =~ "test-config"
    end
  end

  describe "Form - edit" do
    setup [:create_llm_config, :create_and_log_in_user]

    test "updates config with valid data", %{
      conn: conn,
      llm_config: config
    } do
      {:ok, live, _html} =
        live(conn, ~p"/llm-configs/#{config.id}/edit")

      assert live
             |> form("#llm-config-form",
               llm_config: @invalid_attrs
             )
             |> render_change() =~ "can&#39;t be blank"

      update_attrs = %{
        name: "updated-name",
        model: "anthropic/claude-3.5-sonnet",
        position: 5
      }

      assert {:ok, index_live, _html} =
               live
               |> form("#llm-config-form",
                 llm_config: update_attrs
               )
               |> render_submit()
               |> follow_redirect(conn, ~p"/llm-configs")

      html = render(index_live)
      assert html =~ "LLM config updated successfully"
      assert html =~ "updated-name"
    end
  end

  describe "Sync Models" do
    setup [:create_and_log_in_user]

    test "sync button triggers fetch and shows flash", %{
      conn: conn
    } do
      Bodhi.LLMMock
      |> expect(:fetch_models, fn ->
        {:ok,
         [
           %{
             "id" => "openai/gpt-4o",
             "name" => "GPT-4o"
           },
           %{
             "id" => "anthropic/claude-3.5",
             "name" => "Claude 3.5"
           }
         ]}
      end)

      {:ok, live, html} = live(conn, ~p"/llm-configs")

      assert html =~ "Sync Models"

      html =
        live
        |> element("button", "Sync Models")
        |> render_click()

      assert html =~ "2 created"
    end

    test "sync failure shows error flash", %{conn: conn} do
      Bodhi.LLMMock
      |> expect(:fetch_models, fn ->
        {:error, "API timeout"}
      end)

      {:ok, live, _html} = live(conn, ~p"/llm-configs")

      html =
        live
        |> element("button", "Sync Models")
        |> render_click()

      assert html =~ "API timeout"
    end
  end

  describe "auth required" do
    test "redirects unauthenticated user", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} =
               live(conn, ~p"/llm-configs")
    end
  end
end
