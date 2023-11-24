defmodule Hambot.Slack.HTTPClient do
  @post_message_url "https://slack.com/api/chat.postMessage"
  def reply_in_thread(channel, ts, text) do
    Req.post!(@post_message_url,
      auth: {:bearer, Application.get_env(:hambot, :slack)[:bot_oauth_token]},
      json: %{channel: channel, thread_ts: ts, text: text}
    )
  end

  def send_message(channel, text) do
    Req.post!(@post_message_url,
      auth: {:bearer, Application.get_env(:hambot, :slack)[:bot_oauth_token]},
      json: %{channel: channel, text: text}
    )
  end
end
