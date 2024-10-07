defmodule Hambot.Slack.HTTPClient do
  @behaviour Hambot.Slack

  @post_message_url "https://slack.com/api/chat.postMessage"
  @oauth_access_url "https://slack.com/api/oauth.v2.access"

  def reply_in_thread(access_token, channel, ts, text) do
    Req.post(@post_message_url,
      auth: {:bearer, access_token},
      json: %{channel: channel, thread_ts: ts, text: text}
    )
    |> parse_response()
  end

  def send_message(access_token, channel, text) do
    Req.post(@post_message_url,
      auth: {:bearer, access_token},
      json: %{channel: channel, text: text}
    )
    |> parse_response()
  end

  def get_oauth_token(code) do
    Req.post(@oauth_access_url,
      form: %{
        client_id: Application.get_env(:hambot, :slack)[:client_id],
        client_secret: Application.get_env(:hambot, :slack)[:client_secret],
        code: code
      }
    )
    |> case do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  defp parse_response({:ok, %{status: 200, body: %{"ok" => true}}}), do: :ok

  defp parse_response({:ok, %{status: 200, body: %{"ok" => false, "error" => err}}}),
    do: {:error, err}

  defp parse_response({:error, err}), do: {:error, err}
end
