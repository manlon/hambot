ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Hambot.Repo, :manual)
Application.put_env(:hambot, :slack_api, Hambot.Slack.MockClient)
