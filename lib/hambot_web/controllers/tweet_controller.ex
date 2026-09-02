defmodule HambotWeb.TweetController do
  use HambotWeb, :controller
  require Logger

  alias Hambot.Tweet
  alias HambotWeb.TweetLink

  def show(conn, %{"id" => param}) do
    with {:ok, status_id} <- TweetLink.status_id(param),
         {:ok, status} <- Tweet.fetch(status_id) do
      conn
      |> put_root_layout(html: false)
      |> render(:show, layout: false, status: status)
    else
      {:error, reason} when reason in [:invalid, :not_found] ->
        error(conn, :not_found)

      {:error, reason} ->
        Logger.warning("tweet fetch failed for #{inspect(param)}: #{inspect(reason)}")
        error(conn, :bad_gateway)
    end
  end

  defp error(conn, status) do
    conn
    |> put_status(status)
    |> put_view(html: HambotWeb.ErrorHTML)
    |> render(:"#{Plug.Conn.Status.code(status)}")
  end
end
