defmodule HambotWeb.SlackAuthController do
  use HambotWeb, :controller
  alias Hambot.Slack.Team

  def index(conn, %{"code" => code}) do
    {:ok, resp_body} = Hambot.Slack.HTTPClient.get_oauth_token(code)

    if resp_body["ok"] == false do
      IO.inspect(resp_body)

      conn
      |> put_flash(:error, "Error authenticating with Slack")
      |> redirect(to: "/")
    else
      team_params = %{
        name: resp_body["team"]["name"],
        team_id: resp_body["team"]["id"],
        access_token: resp_body["access_token"],
        scope: resp_body["scope"]
      }

      team = Team.add_team_auth(team_params)

      render(conn, :index, layout: false, team: team)
    end
  end
end
