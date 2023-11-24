defmodule Hambot do
  @moduledoc """
  Hambot keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias Hambot.Archive

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

  def archive_urls(payload) do
    collect_urls(payload)
    |> Enum.filter(&Archive.should_archive?/1)
    |> Enum.map(&Archive.make_archive_url/1)
  end

  def api() do
    Application.get_env(:hambot, :slack_api)
  end

  def send_message(channel, text) do
    api().send_message(channel, text)
  end

  def reply_in_thread(channel, ts, text) do
    api().reply_in_thread(channel, ts, text)
  end
end
