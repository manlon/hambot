defmodule Hambot.Slack.HTTPClient do
  @behaviour Hambot.Slack

  @post_message_url "https://slack.com/api/chat.postMessage"
  @oauth_access_url "https://slack.com/api/oauth.v2.access"

  @spec post_message(String.t(), String.t(), keyword()) :: {:ok, String.t()} | {:error, any()}
  defp post_message(access_token, channel, opts) do
    if !Keyword.has_key?(opts, :text) and !Keyword.has_key?(opts, :blocks) do
      raise ArgumentError, "text or blocks must be provided"
    end

    body =
      Keyword.validate!(opts, [
        :channel,
        :text,
        :blocks,
        :thread_ts,
        :username,
        :icon_url,
        :icon_emoji,
        :unfurl_links,
        :unfurl_media
      ])
      |> Enum.into(%{})
      |> Map.merge(%{channel: channel})

    Req.post(@post_message_url,
      auth: {:bearer, access_token},
      json: body
    )
    |> parse_response()
  end

  @impl true
  @spec reply_in_thread(String.t(), String.t(), String.t(), String.t(), keyword()) ::
          {:ok, String.t()} | {:error, any()}
  def reply_in_thread(access_token, channel, ts, text, opts \\ []) do
    opts =
      opts
      |> put_in([:thread_ts], ts)
      |> put_in([:text], text)

    post_message(access_token, channel, opts)
  end

  @impl true
  @spec send_message_text(String.t(), String.t(), String.t(), keyword()) ::
          {:ok, String.t()} | {:error, any()}
  def send_message_text(access_token, channel, text, opts \\ []) do
    opts =
      opts
      |> put_in([:text], text)

    post_message(access_token, channel, opts)
  end

  @impl true
  @spec send_message_blocks(String.t(), String.t(), list(), keyword()) ::
          {:ok, String.t()} | {:error, any()}
  def send_message_blocks(access_token, channel, blocks, opts \\ []) do
    opts =
      opts
      |> put_in([:blocks], blocks)

    post_message(access_token, channel, opts)
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

  defp parse_response({:ok, %{status: 200, body: %{"ok" => true, "ts" => ts}}}), do: {:ok, ts}

  defp parse_response({:ok, %{status: 200, body: %{"ok" => false, "error" => err}}}),
    do: {:error, err}

  defp parse_response({:error, err}), do: {:error, err}
end
