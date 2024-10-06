defmodule Hambot.Slack do
  @callback reply_in_thread(String.t(), String.t(), String.t(), String.t()) ::
              :ok | {:error, any()}
  @callback send_message(String.t(), String.t(), String.t()) :: :ok | {:error, any()}

  def reply_in_thread(team_id, channel, ts, text) do
    impl().reply_in_thread(team_id, channel, ts, text)
  end

  def send_message(team_id, channel, text) do
    impl().send_message(team_id, channel, text)
  end

  defp impl, do: Application.get_env(:hambot, :slack_api)
end
