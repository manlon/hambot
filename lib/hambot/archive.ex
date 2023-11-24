defmodule Hambot.Archive do

  @archive_prefix "https://archive.today/newest/"

  def should_archive?(url) do
    uri = URI.parse(url)
    Hambot.Archive.Server.is_archive?(uri.host)
  end

  def make_archive_url(url) do
    url =
      URI.parse(url)
      |> Map.put(:query, nil)
      |> URI.to_string()

    @archive_prefix <> url
  end
end
