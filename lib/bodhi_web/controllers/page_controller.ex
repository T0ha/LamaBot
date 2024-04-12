defmodule BodhiWeb.PageController do
  use BodhiWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
