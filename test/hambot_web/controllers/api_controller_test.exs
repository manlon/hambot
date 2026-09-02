defmodule HambotWeb.ApiControllerTest do
  use HambotWeb.ConnCase

  import Mox
  import Hambot.FxTwitterFixtures
  import Hambot.TeamFixtures

  alias Hambot.Slack.Team

  setup :verify_on_exit!

  @tweet_url "https://x.com/DPD_/status/2095117900965130416"

  defp message_event(team, text, urls) do
    %{
      "team_id" => team.team_id,
      "event" => %{
        "type" => "message",
        "user" => "U123",
        "channel" => "C123",
        "ts" => "1700000000.000100",
        "text" => text,
        "blocks" => [
          %{
            "type" => "rich_text",
            "elements" => [
              %{
                "type" => "rich_text_section",
                "elements" => Enum.map(urls, &%{"type" => "link", "url" => &1})
              }
            ]
          }
        ]
      }
    }
  end

  defp post_event(conn, event) do
    conn = post(conn, ~p"/api/event", event)
    assert json_response(conn, 200)
    conn
  end

  describe "tweet links" do
    test "posts a context block linking to the viewer page", %{conn: conn} do
      team = team_fixture()

      Hambot.MockFxTwitter
      |> expect(:fetch, fn "2095117900965130416" -> {:ok, fxtwitter_tweet(:quote_with_video)} end)

      Hambot.MockSlackApi
      |> expect(:send_message_blocks, fn token, "C123", blocks, opts ->
        assert token == team.access_token
        assert opts[:unfurl_links] == false
        assert [%{type: "context", elements: [%{type: "mrkdwn", text: text}]}] = blocks
        assert text =~ ~r{<http://localhost(:\d+)?/t/2095117900965130416\|}
        assert text =~ "@DPD_'s post"
        {:ok, "1700000000.000200"}
      end)

      post_event(conn, message_event(team, "look #{@tweet_url}", [@tweet_url]))
    end

    test "replies in thread when tweet_link_mode is thread", %{conn: conn} do
      team = Team.with_prefs(team_fixture())
      :ok = Team.update_pref(team, "tweet_link_mode", "thread")

      Hambot.MockFxTwitter
      |> expect(:fetch, fn "20" -> {:ok, fxtwitter_tweet(:plain)} end)

      Hambot.MockSlackApi
      |> expect(:send_message_text, fn _token, "C123", text, opts ->
        assert text =~ ~r{\Ahttp://localhost(:\d+)?/t/20\z}
        assert opts[:thread_ts] == "1700000000.000100"
        {:ok, "1700000000.000200"}
      end)

      post_event(conn, message_event(team, "x", ["https://twitter.com/jack/status/20"]))
    end

    test "posts nothing when the tweet cannot be fetched", %{conn: conn} do
      team = team_fixture()

      Hambot.MockFxTwitter
      |> expect(:fetch, fn "20" -> {:error, :not_found} end)

      post_event(conn, message_event(team, "x", ["https://x.com/jack/status/20"]))
    end

    test "does nothing when tweet_link_mode is none", %{conn: conn} do
      team = Team.with_prefs(team_fixture())
      :ok = Team.update_pref(team, "tweet_link_mode", "none")

      post_event(conn, message_event(team, "x", [@tweet_url]))
    end

    test "ignores non-tweet links", %{conn: conn} do
      team = team_fixture()
      post_event(conn, message_event(team, "x", ["https://x.com/DPD_", "https://example.com"]))
    end
  end
end
