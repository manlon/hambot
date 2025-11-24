defmodule Hambot.Slack do
  alias Hambot.Slack.Team

  @callback reply_in_thread(%Team{}, String.t(), String.t(), String.t()) ::
              {:ok, String.t()} | {:error, any()}
  @callback send_message_text(%Team{}, String.t(), String.t(), list()) :: {:ok, String.t()} | {:error, any()}
  @callback send_message_blocks(%Team{}, String.t(), String.t(), list()) :: {:ok, String.t()} | {:error, any()}

  def reply_in_thread(team = %Team{}, channel, ts, text, opts \\ []) do
    impl().reply_in_thread(team.access_token, channel, ts, text, opts)
  end

  def send_message_text(team = %Team{}, channel, text, opts \\ []) do
    impl().send_message_text(team.access_token, channel, text, opts)
  end

  def send_message_blocks(team = %Team{}, channel, blocks, opts \\ []) do
    impl().send_message_blocks(team.access_token, channel, blocks, opts)
  end

  defp impl, do: Application.get_env(:hambot, :slack_api)
end
