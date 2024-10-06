defmodule Hambot.Archive do
  alias Hambot.Archive.Domain
  alias Hambot.Slack.Team

  @archive_prefix "https://archive.today/newest/"

  def archive_urls(_, []), do: []

  def archive_urls(team_id, urls) do
    team = Team.find_by_team_id_with_domains(team_id)
    case team do
      nil ->
        []

      team ->
        archive_domains = team.domains |> Enum.map(& &1.domain)
        for url <- urls, should_archive?(url, archive_domains) do
          make_archive_url(url)
        end
    end
  end

  defp should_archive?(url, archive_domains) do
    case URI.parse(url).host do
      nil ->
        false
      host ->
        should_archive_domain?(host, archive_domains)
    end
  end

  defp should_archive_domain?(domain, archive_domains) do
    if domain in archive_domains do
      true
    else
      case String.split(domain, ".", parts: 2) do
        [_first, rest] ->
          should_archive_domain?(rest, archive_domains)

        _ ->
          false
      end
    end
  end

  def make_archive_url(url) do
    url =
      URI.parse(url)
      |> Map.put(:query, nil)
      |> URI.to_string()

    @archive_prefix <> url
  end

 def add_domain(team_id, domain) do
   Team.find_by_team_id(team_id)
   |> Team.add_domain(domain)
 end

 def list_domains(team_id) do
   Domain.list_domains(team_id)
 end
end
