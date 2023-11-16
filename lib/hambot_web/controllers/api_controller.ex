defmodule HambotWeb.ApiController do
  use HambotWeb, :controller
  require Logger

  def index(conn, _params) do
    render(conn, "index.json")
  end

  def event(conn, %{"type" => "url_verification", "challenge" => chal, "token" => tok}) do
    Logger.debug(inspect({"url_verifcaiton", chal, tok}))

    if tok == Application.get_env(:hambot, :slack)[:verification_token] do
      render(conn, "url_verification.json", %{challenge: chal})
    else
      conn
      |> put_status(:forbidden)
      |> render(:"403")
    end
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
