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

  # don't reply to bots (incl us)
  def event(conn, %{
        "event" => %{
          "type" => "message",
          "subtype" => "bot_message"
        }
      }) do
    render(conn, "message.json", %{})
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
    Logger.debug("Ignoring our own message #{user_id}")
    render(conn, "message.json", %{})
  end

  # DM
  def event(conn, %{
        "team_id" => team_id,
        "event" =>
          event = %{
            "type" => "message",
            "channel_type" => "im",
            "channel" => channel,
            "text" => text
          }
      }) do
    team = Team.find_by_team_id!(team_id)
    {:ok, acted?} = process_message(conn, team_id, event)

    if !acted? do
      Commands.respond_to_dm(team, channel, text)
    end

    render(conn, "message.json", %{})
  end

  def event(conn, %{
        "team_id" => team_id,
        "event" => event = %{"type" => "message"}
      }) do
    {:ok, _acted?} = process_message(conn, team_id, event)
    render(conn, "message.json", %{})
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
    team = Team.find_by_team_id!(team_id)
    Commands.respond_to_mention(team, user_id, channel, text)
    render(conn, "message.json", %{})
  end

  def event(conn, params) do
    Logger.debug("unhandled event")
    render(conn, "unknown_event.json", params)
  end

  defp process_message(
         _conn,
         team_id,
         event = %{
           "type" => "message",
           "user" => _user,
           "channel" => channel,
           "ts" => ts,
           "text" => text
         }
       ) do
    Logger.debug("process_message #{inspect(event)}")
    team = Team.find_by_team_id!(team_id)
    urls = Hambot.archive_urls(team, event)

    for url <- urls do
      Logger.debug(
        "replying in thread #{channel} #{ts} #{url} #{team.prefs.prefs.archive_link_mode}"
      )

      case team.prefs.prefs.archive_link_mode do
        :thread -> send_message(team, channel, url, thread_ts: ts)
        :reply -> send_message(team, channel, url)
        :context -> send_message_blocks(team, channel, [build_archive_link_context_block(url)])
        _ -> nil
      end
    end

    cxn_result =
      case Hambot.Puzzle.Connections.score(text) do
        {:ok, score} ->
          send_message(team, channel, "Your Connections score: #{score}")

        _ ->
          nil
      end

    codebro_result =
      if Enum.any?(@codebros, fn bro -> String.contains?(text, bro) end) do
        message = Regex.replace(@mention_pattern, text, "")
        bro_response = Codebro.send_chat(message)
        send_message(team, channel, bro_response, username: "codebro", icon_url: @codebro_icon)
      end

    nothing? = Enum.empty?(urls) && is_nil(cxn_result) && is_nil(codebro_result)
    {:ok, !nothing?}
  end

  defp send_message(team = %Team{}, channel, text, opts \\ []) do
    opts = Keyword.merge(opts, unfurl_links: false, unfurl_media: false)
    Slack.send_message_text(team, channel, text, opts)
  end

  defp send_message_blocks(team = %Team{}, channel, blocks, opts \\ []) do
    opts = Keyword.merge(opts, unfurl_links: false, unfurl_media: false)
    Slack.send_message_blocks(team, channel, blocks, opts)
  end

  defp build_archive_link_context_block(url) do
    %{
      type: "context",
      elements: [
        %{
          type: "mrkdwn",
          text: "here's an <#{url}|archived version>"
        }
      ]
    }
  end
end
