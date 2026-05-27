# McpServer Grok Plugin

Connect [Grok 4.3](https://x.ai) coding agent CLI / TUI to [McpServer](https://github.com/sharpninja/McpServer) for workspace-scoped TODO management, session logging, requirements tracking, GraphRAG, and full agent session continuity.

## Features

- **Auto-connect** via `AGENTS-README-FIRST.yaml` marker file discovery with HMAC-SHA256 signature verification
- **Session hooks** — automatic session creation, turn tracking, context reload after compaction
- **Plan tracking** — auto-creates MCP TODO when a plan is approved, syncs updates on plan edits
- **Offline resilience** — local YAML cache for writes when MCP server is unavailable, automatic flush on reconnect
- **Core skills**: TODO, Session Log, Requirements, GraphRAG, Workspace — implemented as native Grok skills (SKILL.md) with optional `mcpserver-repl --agent-stdio` REPL transport for full contract parity.

## Prerequisites

- [.NET 9.0 SDK](https://dotnet.microsoft.com/download)
- [GitHub CLI](https://cli.github.com/) (`gh`) — authenticated
- [McpServer](https://github.com/sharpninja/McpServer) running with a workspace configured

The plugin auto-installs `mcpserver-repl` (dotnet global tool) from GitHub releases on first use.

## Installation

```bash
# Grok loads skills from ~/.grok/skills or marketplace plugins.
# Copy or symlink the skills/ directory contents into your Grok skills location,
# or use the Grok McpServer tools-bucket entry.
# The hooks/ and lib/ provide optional bootstrap for agents that support bash hooks.
```

## How It Works

1. Grok loads the skills from this plugin (or a marketplace copy) into `~/.grok/skills`.
2. On session start / first relevant prompt, the skills perform (or guide) marker discovery, HMAC-SHA256 signature verification, and health nonce check exactly as required by the workspace `AGENTS-README-FIRST.yaml`.
3. Session and turn lifecycle is recorded via the Session skill (workflow.sessionlog.*) or native Grok hook integration.
4. All core operations (TODO, session log, requirements, GraphRAG) are available as Grok skills with full parity to the McpServer REPL contract. Optional REPL transport remains available for advanced/ streaming scenarios.

## Skills (Grok-native + REPL parity)

The plugin provides Grok SKILL.md files for:
- **todo** — full TODO lifecycle, streaming plan/implement/status, requirement analysis, canonical ID rules.
- **session** — bootstrap, openSession, beginTurn / update / appendDialog (with decision category) / appendActions (design_decision type) / completeTurn, history.
- **requirements** — FR/TR/TEST creation, mapping, wiki generation.
- **graphrag** — ad-hoc entity/relationship ingestion and querying.
- **workspace** — context and policy helpers.

All map to the same `workflow.*` namespaces as the original REPL contract for full compatibility. Grok can invoke them directly via its skill system; the original REPL transport is retained for power users and cross-agent parity.

## Offline Cache

When MCP server is unavailable, writes are cached as YAML files in `cache/pending/`. The cache flushes automatically on:
- Next skill invocation (opportunistic)
- Session end hook
- Manual: `hooks/scripts/cache-flush.sh`

Items retry up to 3 times before being marked as failed.

## Development

```bash
# Run tests
bats tests/

# Test a specific phase
bats tests/hooks.bats
bats tests/skills.bats
```

## License

MIT
