defmodule HambotWeb.ApiController do
  use HambotWeb, :controller
  require Logger
  alias Hambot.Commands

  plug :auth_token

  def auth_token(conn, _options) do
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

  def event(conn, %{"event" => %{"hidden" => true}}) do
    render(conn, "message.json", %{urls: []})
  end

  def event(conn, %{
        "event" => e = %{"type" => "message", "channel" => channel, "ts" => ts, "text" => text}
      }) do
    urls = Hambot.archive_urls(e)

    for url <- urls do
      Logger.debug("replying in thread #{channel} #{ts} #{url}")
      Hambot.reply_in_thread(channel, ts, url)
    end

    case Hambot.Puzzle.Connections.score(text) do
      {:ok, score} ->
        Hambot.send_message(channel, "Your Connections score: #{score}")

      _ ->
        nil
    end

    render(conn, "message.json", %{urls: urls})
  end

  def event(conn, %{
        "authorizations" => [
          %{"user_id" => user_id} | _
        ],
        "event" => %{
          "type" => "app_mention",
          "channel" => channel,
          "ts" => _ts,
          "text" => text
        }
      }) do
    Commands.respond_to_mention(user_id, channel, text)
    render(conn, "message.json", %{})
  end

def event(conn, params) do
    Logger.debug("unhandled event")
    render(conn, "unknown_event.json", params)
  end
end
