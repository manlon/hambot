defmodule HambotWeb.TweetLink do
  @moduledoc """
  Builds and decodes links to the tweet viewer page.
  """

  use HambotWeb, :verified_routes

  @spec viewer_url(String.t()) :: String.t()
  def viewer_url(status_id), do: url(~p"/t/#{status_id}")

  @spec status_id(String.t()) :: {:ok, String.t()} | {:error, :invalid}
  def status_id(param) when is_binary(param) do
    if Regex.match?(~r/\A\d{1,25}\z/, param), do: {:ok, param}, else: {:error, :invalid}
  end
end
