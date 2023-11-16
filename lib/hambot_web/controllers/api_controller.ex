defmodule HambotWeb.ApiController do
  use HambotWeb, :controller
  require Logger

  plug :auth_token

  def auth_token(conn, options) do
    token = conn.body_params["token"]

    if token == Application.get_env(:hambot, :slack)[:verification_token] do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> render(:"403")
      |> halt()
    end
  end

  def index(conn, _params) do
    render(conn, "index.json")
  end

  def event(conn, %{"type" => "url_verification", "challenge" => chal}) do
    Logger.debug(inspect({"url_verifcaiton", chal}))
    render(conn, "url_verification.json", %{challenge: chal})
  end

  def event(conn, %{"event" => e = %{"hidden" => true}}) do
    render(conn, "message.json", %{urls: []})
  end

  def event(conn, %{"event" => e = %{"type" => "message", "channel" => channel, "ts" => ts}}) do
    urls = Hambot.archive_urls(e)

    for url <- urls do
      Logger.debug("replying in thread #{channel} #{ts} #{url}")
      Hambot.reply_in_thread(channel, ts, url)
    end

    render(conn, "message.json", %{urls: urls})
  end

  def event(conn, params) do
    Logger.debug("unhandled event")
    Logger.debug(inspect(params))
    render(conn, "unknown_event.json", params)
  end
end
