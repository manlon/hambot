defmodule Hambot.Slack.MockClient do
  require Logger

  def reply_in_thread(channel, ts, text) do
    Logger.debug("MOCK: replying to #{channel} #{ts} with #{text}")
    :ok
  end

  def send_message(channel, text) do
    Logger.debug("MOCK: sending #{text} to #{channel}")
    :ok
  end
end
