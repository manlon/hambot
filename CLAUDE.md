# Hambot - Claude Code Reference

## Overview

Hambot is a multi-functional Slack bot built with Elixir/Phoenix. It supports multiple Slack workspaces via OAuth and provides several automated features including URL archiving, chatbot interactions, puzzle scoring, and NHL game notifications.

## Tech Stack

- **Elixir 1.14+** with **Phoenix 1.7.18**
- **Ecto 3.12** with **SQLite** (ecto_sqlite3) for persistence
- **Oban 2.18** (Lite engine) for background job processing
- **DuckDB + Explorer** for analytics queries on CSV datasets
- **NimbleParsec 1.4** for parsing commands, puzzle results, and Slack formatting
- **Req 0.4.4** for HTTP client (Slack API calls)

## Project Structure

```
lib/
├── hambot/                    # Core business logic
│   ├── application.ex         # OTP supervisor, initializes all subsystems
│   ├── commands.ex            # Command dispatcher for mentions/DMs
│   ├── commands/parser.ex     # NimbleParsec parsers for commands
│   ├── slack/                 # Slack integration
│   │   ├── http_client.ex     # Slack API implementation
│   │   ├── team.ex            # Team schema and DB operations
│   │   └── team_pref.ex       # Team preferences (modified - check git status)
│   ├── archive/               # URL archiving to archive.today
│   ├── puzzle/connections.ex  # NYT Connections puzzle scorer
│   ├── game_chat/kraken.ex    # NHL scheduled game threads (Oban worker)
│   └── codebro.ex             # Markov chain chatbot (GenServer)
└── hambot_web/
    ├── controllers/
    │   ├── api_controller.ex      # Main Slack event handler
    │   └── slack_auth_controller.ex  # OAuth flow
    └── router.ex                  # Routes: /api/event, OAuth callback

priv/
├── datasets/nhl_schedule.csv  # Static NHL schedule data
└── repo/migrations/           # Database migrations
```

## Main Features

### 1. URL Archiving (`lib/hambot/archive.ex`)
- Detects URLs in Slack messages for configured domains
- Creates archive.today links automatically
- Supports subdomain matching
- Per-team configuration of response mode (thread, reply, context block, none)
- Commands: `@hambot domain add <domain>`, `@hambot domain list`

### 2. Codebro Chatbot (`lib/hambot/codebro.ex`)
- Responds to mentions of "@codebro" or user ID "U02CYD8A6RE"
- GenServer implementing trigram-based Markov chains
- Learns from all messages, persists brain asynchronously via Task.Supervisor
- Brain stored in configurable file path (see config)
- Seeds responses using words from input message

### 3. NYT Connections Scorer (`lib/hambot/puzzle/connections.ex`)
- Detects Connections puzzle emoji grids posted in Slack
- Parses colored squares (yellow, green, blue, purple)
- Calculates scores based on color order and mistakes
- Auto-replies with score

### 4. NHL Game Chat (`lib/hambot/game_chat/kraken.ex`)
- Seattle Kraken game notifications (Oban scheduled worker)
- Queries `priv/datasets/nhl_schedule.csv` using DuckDB
- Creates threads 15 minutes before game time
- Schedule rebuilt on application startup
- Posts to configured channels (via team preferences)

### 5. Team Preferences
- Per-workspace configuration storage
- Commands: `@hambot team pref list`, `@hambot team pref set <name> <value>`
- Settings: `archive_link_mode`, `game_chats` (channels for NHL threads)

## Architecture Patterns

### Slack API Behavior Pattern
The Slack integration uses an Elixir behavior (`Hambot.Slack`) for testability:
- `Hambot.Slack.HttpClient` - production implementation
- Uses Mox in tests for mocking
- Configured via `config :hambot, :slack` application env

### Event Handling Flow
1. Slack sends events to `POST /api/event` (HambotWeb.ApiController)
2. Token verification checks Slack signing secret
3. Events dispatched by type:
   - `url_verification` - OAuth setup
   - `message` events - trigger archiving, Codebro, Connections scoring
   - `app_mention` - command parsing via `Hambot.Commands`

### Background Jobs
- Oban with Lite engine (no Postgres required)
- `Hambot.GameChat.Kraken` worker scheduled via `Hambot.Application.rebuild_nhl_oban_schedule/0`
- Codebro brain updates run async via Task.Supervisor to avoid blocking

### Data Storage
- **SQLite** - Teams, domains, preferences (via Ecto)
- **DuckDB** - Analytics queries on NHL schedule CSV (via ADBC)
- **File** - Codebro Markov chain brain (configurable path)

## Development Notes

### Database
- SQLite dev/test databases in `priv/repo/`
- Migrations in `priv/repo/migrations/`
- Run with: `mix ecto.migrate`

### Configuration
- `config/config.exs` - shared config
- `config/dev.exs`, `config/prod.exs` - environment-specific
- `config/runtime.exs` - runtime config (Slack tokens, secrets)

### Testing
- Uses Mox for Slack API mocking
- Run tests: `mix test`

### Parsers
Multiple NimbleParsec-based parsers in `lib/hambot/commands/parser.ex`:
- Command parsing (mentions, links, text)
- Connections puzzle grid parsing
- NHL schedule time parsing
- Slack message formatting (mentions, links)

## Important Commands

### Bot Commands (via @hambot mention or DM)
- `@hambot domain add <domain>` - Add domain to archive list
- `@hambot domain list` - Show configured domains
- `@hambot team pref list` - Show team preferences
- `@hambot team pref set <name> <value>` - Set preference

### Mentions
- `@codebro <message>` - Get Markov chain response
- Post Connections results - Auto-scored
- URLs from configured domains - Auto-archived

## Git

Main branch: `main`. This repo is managed with jj; use jj commands.

## OAuth Setup

The bot requires Slack app configuration:
- OAuth redirect: `/oauth/callback`
- Event subscriptions: `/api/event`
- Required scopes: chat:write, channels:history, groups:history, im:history, mpim:history
- Store client ID, client secret, signing secret in runtime config
