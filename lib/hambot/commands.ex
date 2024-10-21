defmodule Hambot.Commands do
  alias Hambot.Commands.Parser
  alias Hambot.Slack
  alias Hambot.Slack.Team
  alias Hambot.Archive

  def respond_to_mention(team = %Team{}, user_id, channel, text) do
    text = String.trim(text)

    case Parser.parse_mention(text) do
      {:ok, [^user_id | rest], _, _, _, _} ->
        do_command(rest, team, channel)

      _ ->
        respond_to_unknown(team, channel)
    end
  end

  def respond_to_dm(team = %Team{}, channel, text) do
    case Parser.parse_command(text) do
      {:ok, args, _, _, _, _} ->
        do_command(args, team, channel)
    end
  end

  def do_command(["domain", "add", domain], team = %Team{}, channel) do
    case Parser.parse_link(domain) do
      {:ok, [domain], _, _, _, _} ->
        case Archive.add_domain(team, domain) do
          {:ok, _} ->
            send_message(team, channel, "added #{domain} to the archive list :ham:")

          {:error, msg} ->
            send_message(team, channel, "couldn't add domiain #{domain}: #{msg}")
        end

      _ ->
        send_message(team, channel, "couldn't parse domain #{domain}")
    end
  end

  def do_command(["domain", "list"], team = %Team{}, channel) do
    domains = Archive.list_domains(team)
    msgs = ["here are the domains :ham: knows about" | domains]
    send_message(team, channel, Enum.join(msgs, "\n"))
  end

  def do_command(other_args, team = %Team{}, channel) do
    msgs = ["don't know how to" | other_args]
    send_message(team, channel, Enum.join(msgs, " "))
  end

  def respond_to_unknown(team = %Team{}, channel) do
    send_message(team, channel, "ham")
  end

  defp send_message(team = %Team{}, channel, msg) do
    Slack.send_message(team, channel, msg)
  end
end
