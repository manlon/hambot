defmodule Hambot.Tweet.FxTwitter.HTTPClient do
  @behaviour Hambot.Tweet.FxTwitter

  @base_url "https://api.fxtwitter.com/status/"

  @impl true
  def fetch(status_id) do
    Req.get(@base_url <> status_id,
      headers: [accept: "application/json", user_agent: "hambot"],
      retry: false
    )
    |> case do
      {:ok, %{status: 200, body: %{"tweet" => tweet}}} when is_map(tweet) ->
        {:ok, tweet}

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      # Malformed ids fall through to FxTwitter's HTML landing page.
      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        {:error, :not_found}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
