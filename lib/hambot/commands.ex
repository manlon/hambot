defmodule Hambot.Commands do
  alias Hambot.Commands.Parser
  alias Hambot.Archive.Server, as: Archive
  alias Hambot.Slack

  def respond_to_mention(user_id, channel, text) do
    text = String.trim(text)

    case Parser.parse_mention(text) do
      {:ok, [^user_id | rest], _, _, _, _} ->
        do_command(rest, channel)

      _ ->
        respond_to_unknown(channel)
    end
  end

  def do_command(["domain", "add", domain], channel) do
    case Parser.parse_link(domain) do
      {:ok, [domain], _, _, _, _} ->
        case Archive.add_domain(domain) do
          :ok ->
            Slack.send_message(channel, "added #{domain} to the archive list :ham:")

          {:error, msg} ->
            Slack.send_message(channel, "couldn't add domiain #{domain}: #{msg}")
        end

      _ ->
        Slack.send_message(channel, "couldn't parse domain #{domain}")
    end
  end

  def do_command(["domain", "list"], channel) do
    domains = Archive.list_domains()
    msgs = ["here are the domains :lincoln_shades: knows about" | domains]
    Slack.send_message(channel, Enum.join(msgs, "\n"))
  end

  def do_command(other_args, channel) do
    msgs = ["don't know how to" | other_args]
    Slack.send_message(channel, Enum.join(msgs, " "))
  end

  def respond_to_unknown(channel) do
    Slack.send_message(channel, "ham")
  end
end
