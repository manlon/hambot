defmodule Hambot do
  @moduledoc """
  Hambot keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def collect_urls(payload), do: Enum.uniq(collect_urls(payload, []))

  defp collect_urls(%{"type" => "link", "url" => url}, acc) do
    [url | acc]
  end

  defp collect_urls(s, acc) when not is_map(s) and not is_list(s), do: acc

  defp collect_urls(payload = %{}, acc) do
    Enum.reduce(payload, acc, fn {_k, v}, acc ->
      collect_urls(v, acc)
    end)
  end

  defp collect_urls(payload, acc) when is_list(payload) do
    Enum.reduce(payload, acc, fn v, acc ->
      collect_urls(v, acc)
    end)
  end

  @archive_domains [
    "nytimes.com",
    "washingtonpost.com",
    "seattletimes.com",
    "ft.com",
    "bloomberg.com",
    "cincinnati.com"
  ]

  def should_archive?(url) do
    uri = URI.parse(url)
    Enum.any?(@archive_domains, &String.ends_with?(uri.host, &1))
  end

  def make_archive_url(url) do
    url =
      URI.parse(url)
      |> Map.put(:query, nil)
      |> URI.to_string()

    "https://archive.today/newest/#{url}"
  end

  def archive_urls(payload) do
    collect_urls(payload)
    |> Enum.filter(&should_archive?/1)
    |> Enum.map(&make_archive_url/1)
  end

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
