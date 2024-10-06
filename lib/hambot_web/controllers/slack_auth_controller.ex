defmodule HambotWeb.SlackAuthController do
  use HambotWeb, :controller

  def index(conn, %{"code" => code}) do
    {:ok, resp_body} = Hambot.Slack.HTTPClient.get_oauth_token(code)
    render(conn, :index, layout: false, beep: resp_body)
  end
end
