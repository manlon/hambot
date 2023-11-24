defmodule Hambot.Slack.HTTPClient do
  @behaviour Hambot.Slack

  @post_message_url "https://slack.com/api/chat.postMessage"
  def reply_in_thread(channel, ts, text) do
    Req.post(@post_message_url,
      auth: {:bearer, Application.get_env(:hambot, :slack)[:bot_oauth_token]},
      json: %{channel: channel, thread_ts: ts, text: text}
    )
    |> parse_response()
  end

  def send_message(channel, text) do
    Req.post(@post_message_url,
      auth: {:bearer, Application.get_env(:hambot, :slack)[:bot_oauth_token]},
      json: %{channel: channel, text: text}
    )
    |> parse_response()
  end

  defp parse_response({:ok, %{status: 200, body: %{"ok" => true}}}), do: :ok

  defp parse_response({:ok, %{status: 200, body: %{"ok" => false, "error" => err}}}),
    do: {:error, err}

  defp parse_response({:error, err}), do: {:error, err}
end
