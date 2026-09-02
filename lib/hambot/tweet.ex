defmodule Hambot.Tweet do
  @moduledoc """
  Detects links to tweets and fetches them, so that Hambot can offer a view of
  the content to people without an X account.
  """

  alias Hambot.Tweet.FxTwitter
  alias Hambot.Tweet.Status

  @hosts ~w(x.com twitter.com fxtwitter.com fixupx.com)
  @status_path ~r"\A/(?:[A-Za-z0-9_]{1,15}|i/web)/status(?:es)?/(\d{1,25})(?:/|\z)"

  @doc """
  Extracts tweet status ids from a list of URLs, preserving order and
  deduplicating by id. Returns `{status_id, original_url}` pairs.
  """
  @spec status_links([String.t()]) :: [{String.t(), String.t()}]
  def status_links(urls) do
    urls
    |> Enum.flat_map(fn url ->
      case status_id(url) do
        nil -> []
        id -> [{id, url}]
      end
    end)
    |> Enum.uniq_by(&elem(&1, 0))
  end

  @spec status_id(String.t()) :: String.t() | nil
  def status_id(url) when is_binary(url) do
    uri = URI.parse(url)

    with true <- tweet_host?(uri.host),
         path when is_binary(path) <- uri.path,
         [_, id] <- Regex.run(@status_path, path) do
      id
    else
      _ -> nil
    end
  end

  defp tweet_host?(nil), do: false

  defp tweet_host?(host) do
    host = String.downcase(host)
    host in @hosts or Enum.any?(@hosts, &String.ends_with?(host, "." <> &1))
  end

  @spec fetch(String.t()) :: {:ok, Status.t()} | {:error, :not_found | term()}
  def fetch(status_id) do
    with {:ok, raw} <- FxTwitter.fetch(status_id) do
      {:ok, Status.from_fxtwitter(raw)}
    end
  end
end
