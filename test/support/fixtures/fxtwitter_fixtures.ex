defmodule Hambot.FxTwitterFixtures do
  @moduledoc """
  Captured responses from api.fxtwitter.com, as the raw `tweet` map.
  """

  @fixture_dir Path.expand("fxtwitter", __DIR__)

  @doc """
  `:plain` is a text-only tweet; `:quote_with_video` quotes a tweet that
  carries a video.
  """
  def fxtwitter_tweet(name) when name in [:plain, :quote_with_video] do
    @fixture_dir
    |> Path.join("#{name}.json")
    |> File.read!()
    |> Jason.decode!()
    |> Map.fetch!("tweet")
  end
end
