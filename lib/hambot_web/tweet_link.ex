defmodule HambotWeb.TweetLink do
  @moduledoc """
  Builds and decodes links to the tweet viewer page.

  The status id travels encrypted with the endpoint's secret, so only links
  minted by hambot resolve; the viewer can't be pointed at arbitrary tweets.
  """

  use HambotWeb, :verified_routes

  @salt "tweet viewer"

  @spec viewer_url(String.t()) :: String.t()
  def viewer_url(status_id), do: url(~p"/t/#{token(status_id)}")

  @spec token(String.t()) :: String.t()
  def token(status_id) when is_binary(status_id) do
    Phoenix.Token.encrypt(HambotWeb.Endpoint, @salt, status_id)
  end

  @spec status_id(String.t()) :: {:ok, String.t()} | {:error, :invalid}
  def status_id(token) when is_binary(token) do
    with {:ok, id} when is_binary(id) <-
           Phoenix.Token.decrypt(HambotWeb.Endpoint, @salt, token, max_age: :infinity),
         true <- Regex.match?(~r/\A\d{1,25}\z/, id) do
      {:ok, id}
    else
      _ -> {:error, :invalid}
    end
  end
end
