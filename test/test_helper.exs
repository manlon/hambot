ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Hambot.Repo, :manual)

Mox.defmock(Hambot.MockSlackApi, for: Hambot.Slack)
Application.put_env(:hambot, :slack_api, Hambot.MockSlackApi)
