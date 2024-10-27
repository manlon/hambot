defmodule Hambot.Slack do
  alias Hambot.Slack.Team

  @callback reply_in_thread(%Team{}, String.t(), String.t(), String.t()) ::
              :ok | {:error, any()}
  @callback send_message(%Team{}, String.t(), String.t(), list()) :: :ok | {:error, any()}

  def reply_in_thread(team = %Team{}, channel, ts, text, opts \\ []) do
    impl().reply_in_thread(team.access_token, channel, ts, text, opts)
  end

  def send_message(team = %Team{}, channel, text, opts \\ []) do
    impl().send_message(team.access_token, channel, text, opts)
  end

  defp impl, do: Application.get_env(:hambot, :slack_api)
end
