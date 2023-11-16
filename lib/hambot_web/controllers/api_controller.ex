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

  def event(conn, %{"event" => e = %{"type" => "message"}}) do
    urls = Hambot.archive_urls(e)
    render(conn, "message.json", %{urls: urls})
  end

  def event(conn, params) do
    Logger.debug("unhandled event")
    render(conn, "unknown_event.json", params)
  end
end
