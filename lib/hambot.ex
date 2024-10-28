defmodule Hambot do
  @moduledoc """
  Hambot keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  alias Hambot.Slack.Team

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

  def archive_urls(team = %Team{}, payload) do
    urls = collect_urls(payload)
    Archive.archive_urls(team, urls)
  end
end
