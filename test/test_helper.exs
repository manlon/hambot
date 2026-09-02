ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Hambot.Repo, :manual)

Mox.defmock(Hambot.MockSlackApi, for: Hambot.Slack)
Application.put_env(:hambot, :slack_api, Hambot.MockSlackApi)

Mox.defmock(Hambot.MockFxTwitter, for: Hambot.Tweet.FxTwitter)
Application.put_env(:hambot, :fxtwitter_api, Hambot.MockFxTwitter)
