defmodule LifeGameWeb.PageController do
  use LifeGameWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
