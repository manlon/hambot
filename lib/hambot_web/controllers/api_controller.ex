defmodule HambotWeb.ApiController do
  use HambotWeb, :controller
  require Logger
  alias Hambot.Commands
  alias Hambot.Slack
  alias Hambot.Slack.Team
  alias Hambot.Codebro

  plug :auth_token

  @codebros ["U02CYD8A6RE", "codebro"]
  @codebro_icon "https://avatars.slack-edge.com/2021-08-22/2400869791558_95cf8760b54dfd0169e4_512.png"
  @mention_pattern ~r/<@U[0-9A-Z]+>/

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

  # don't reply to our own messages
  def event(conn, %{
        "authorizations" => [
          %{"user_id" => user_id} | _
        ],
        "event" => %{
          "user" => user_id
        }
      }) do
    render(conn, "message.json", %{})
  end

  def event(conn, %{
        "team_id" => team_id,
        "event" => e = %{"type" => "message", "channel" => channel, "ts" => ts, "text" => text}
      }) do
    urls = Hambot.archive_urls(team_id, e)

    for url <- urls do
      Logger.debug("replying in thread #{channel} #{ts} #{url}")
      reply_in_thread(team_id, channel, ts, url)
    end

    case Hambot.Puzzle.Connections.score(text) do
      {:ok, score} ->
        send_message(team_id, channel, "Your Connections score: #{score}")

      _ ->
        nil
    end

    if Enum.any?(@codebros, fn bro -> String.contains?(text, bro) end) do
      message = Regex.replace(@mention_pattern, text, "")
      bro_response = Codebro.send_chat(message)
      send_message(team_id, channel, bro_response, "codebro", @codebro_icon)
    end

    render(conn, "message.json", %{urls: urls})
  end

  def event(conn, %{
        "authorizations" => [
          %{"user_id" => user_id} | _
        ],
        "team_id" => team_id,
        "event" => %{
          "type" => "app_mention",
          "channel" => channel,
          "ts" => _ts,
          "text" => text
        }
      }) do
    Commands.respond_to_mention(team_id, user_id, channel, text)
    render(conn, "message.json", %{})
  end

  def event(conn, params) do
    Logger.debug("unhandled event")
    render(conn, "unknown_event.json", params)
  end

  defp send_message(team_id, channel, text, username \\ nil, icon_url \\ nil) do
    token = Team.get_access_token(team_id)
    Slack.send_message(token, channel, text, username, icon_url)
  end

  defp reply_in_thread(team_id, channel, ts, msg) do
    token = Team.get_access_token(team_id)
    Slack.reply_in_thread(token, channel, ts, msg)
  end
end
