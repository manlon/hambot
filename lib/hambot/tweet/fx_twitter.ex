defmodule Hambot.Tweet.FxTwitter do
  @moduledoc """
  Behaviour for the public FxTwitter API (https://api.fxtwitter.com), which
  returns tweet JSON without authentication.
  """

  @callback fetch(String.t()) :: {:ok, map()} | {:error, :not_found | term()}

  @spec fetch(String.t()) :: {:ok, map()} | {:error, :not_found | term()}
  def fetch(status_id), do: impl().fetch(status_id)

  defp impl, do: Application.get_env(:hambot, :fxtwitter_api)
end
