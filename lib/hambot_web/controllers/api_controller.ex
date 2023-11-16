defmodule HambotWeb.ApiController do
  use HambotWeb, :controller

  def index(conn, _params) do
    render(conn, "index.json")
  end
end
