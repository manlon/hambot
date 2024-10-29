defmodule Hambot.Commands do
  alias Hambot.Commands.Parser
  alias Hambot.Slack
  alias Hambot.Slack.Team
  alias Hambot.Archive

  def respond_to_mention(team = %Team{}, user_id, channel, text) do
    text = String.trim(text)

    case Parser.parse_mention(text) do
      {:ok, [^user_id | rest], _, _, _, _} ->
        case do_command(rest, team, channel) do
          :ok ->
            :ok

          {:error, :unknown} ->
            respond_to_unknown(team, channel, "don't know how to #{Enum.join(rest, " ")}")
        end

      _ ->
        respond_to_unknown(team, channel)
    end
  end

  def respond_to_dm(team = %Team{}, channel, text) do
    case Parser.parse_command(text) do
      {:ok, args, _, _, _, _} ->
        case do_command(args, team, channel) do
          :ok ->
            :ok

          {:error, :unknown} ->
            respond_to_unknown(team, channel)
        end
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

  def do_command(["team", "pref", "list"], team = %Team{}, channel) do
    pref_lines =
      team.prefs.prefs
      |> Map.from_struct()
      |> Enum.map(fn {k, v} -> "#{k}: #{v}" end)

    msgs = ["here are the preferences for #{team.name}" | pref_lines]
    send_message(team, channel, Enum.join(msgs, "\n"))
  end

  def do_command(["team", "pref", "set", name, val], team = %Team{}, channel) do
    case Team.update_pref(team, name, val) do
      :ok ->
        send_message(team, channel, "set #{name} to #{val}")

      {:error, msg} ->
        send_message(team, channel, "error: #{msg}")
    end
  end

  def do_command(_args, %Team{}, _channel) do
    {:error, :unknown}
  end

  def respond_to_unknown(team = %Team{}, channel, extra \\ nil) do
    suffix = if extra, do: " (#{extra})", else: ""
    msg = "ham#{suffix}"
    send_message(team, channel, msg)
  end

  defp send_message(team = %Team{}, channel, msg) do
    Slack.send_message_text(team, channel, msg)
  end
end
