defmodule BodhiWeb.Router do
  use BodhiWeb, :router
  import Oban.Web.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {BodhiWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug BodhiWeb.Plugs.Auth
  end

  scope "/", BodhiWeb do
    pipe_through [:browser, :auth]

    get "/logout", AuthController, :logout
    oban_dashboard("/oban")

    live "/users", UserLive.Index, :index
    live "/users/:id/edit", UserLive.Index, :edit

    live "/chats", ChatLive.Index, :index
    live "/chats/:chat_id/messages", ChatLive.Messages, :index

    # live "/chats/:id", ChatLive.Show, :show

    live "/prompts", PromptLive.Index, :index
    live "/prompts/new", PromptLive.Index, :new
    live "/prompts/:id/edit", PromptLive.Index, :edit

    live "/pages", PageLive.Index, :index
    live "/pages/new", PageLive.Form, :new
    live "/pages/:id", PageLive.Show, :show
    live "/pages/:id/edit", PageLive.Form, :edit
  end

  scope "/", BodhiWeb do
    pipe_through :browser

    get "/", PageController, :index

    get "/login", AuthController, :login
    get "/p/:slug", PageController, :page
  end

  # Other scopes may use custom stacks.
  # scope "/api", BodhiWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BodhiWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
