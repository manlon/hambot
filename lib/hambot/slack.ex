defmodule Hambot.Slack do
  @callback reply_in_thread(String.t(), String.t(), String.t()) :: :ok | {:error, any()}
  @callback send_message(String.t(), String.t()) :: :ok | {:error, any()}

  def reply_in_thread(channel, ts, text) do
    impl().reply_in_thread(channel, ts, text)
  end

  def send_message(channel, text) do
    impl().send_message(channel, text)
  end

  defp impl, do: Application.get_env(:hambot, :slack_api)
end
