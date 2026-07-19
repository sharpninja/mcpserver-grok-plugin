# McpServer Grok Plugin — Usage for Grok 4.3 Coding Agent CLI / TUI

This directory is a fork/adaptation of `mcpserver-claude-code-plugin` for the **Grok 4.3** interactive CLI / TUI (and compatible Grok agents).

It provides:

- Native Grok `SKILL.md` files under `skills/` (todo, session, requirements, graphrag, workspace).
- Discoverable MCP tools through the Streamable HTTP endpoint in `.mcp.json`, plus full contract parity with the McpServer workflow shim (`workflow.*` namespaces) via plugin helpers.
- Hook scripts and lib/ (bash reference implementation + pwsh emphasis for this workspace).
- Offline cache support and marker bootstrap logic (signature + nonce) exactly as required by `AGENTS-README-FIRST.yaml`.

## Recommended Loading for Grok

1. Copy or symlink the contents of `skills/` into your personal Grok skills location (`~/.grok/skills` or a marketplace plugin directory).
2. Grok will discover the skills on next start / relevant prompt (e.g. "start session", "create a todo", "list requirements").
3. Use `grok inspect`, `grok mcp doctor mcpserver`, or `/mcps` to confirm the enabled plugin exposes the `mcpserver` MCP entry. The MCP entry should connect to `http://localhost:7147/mcp-transport`; workflow shim helpers still require `mcpserver-repl` (the dotnet global tool) on PATH.

Preferred runtime in this workspace: **PowerShell 7+ (`pwsh`)** via `hooks/hooks.json` → `hooks/scripts/*.ps1` → `lib/plugin-hook.ps1`.

Bash `hooks/scripts/*.sh` + `lib/*.sh` are retained for **Model C** multi-host portability and BATS smoke (`tests/smoke.bats`). They are **not** what Grok runs in production unless you re-point `hooks.json`. Dual-stack behavior differences are listed in `lib/GAPS.md`.

## Bootstrap (Marker + Signature + Nonce)

The skills and hooks implement (or guide) the exact flow required by the workspace marker:

- Read `AGENTS-README-FIRST.yaml`
- Verify HMAC-SHA256 signature using the workspace API key
- Call `/health?nonce=...` and confirm echo
- Only then open sessions, create TODOs, etc.

**Production reference:** `hooks/scripts/session-start.ps1` → `lib/plugin-hook.ps1` (and skills for guided bootstrap).  
**Portable/Model C reference:** `hooks/scripts/session-start.sh` → `lib/hook-lib.sh`.  
On Grok, skills perform equivalent checks where possible and fall back gracefully to `MCP_UNTRUSTED` / local-only mode when the server is unavailable (as required by policy).

## Session / Turn Lifecycle (GrokCode)

Use the **session** skill (or the plugin shim for the underlying `workflow.sessionlog.*` methods) with the canonical naming:

- SessionId: `GrokCode-YYYYMMDDTHHMMSSZ-slug`
- RequestId: `req-YYYYMMDDTHHMMSSZ-slug`
- `sourceType` / agent prefix: `GrokCode` (Pascal-Case)

All design decisions must be logged as `appendDialog` (category: decision) **and** `appendActions` (type: design_decision).

The `workflow.sessionlog.*`, `workflow.todo.*`, and `workflow.requirements.*` names are plugin shim/REPL method names. They are not expected to appear as literal Grok `search_tool` results. If the TUI exposes `pwsh` but not a dedicated workflow tool, call `lib\repl-invoke.ps1` from this plugin root with `-Method <workflow.method>` and YAML params.

## TODO / Requirements

The **todo** and **requirements** skills implement the full contract (create, query, streaming plan/implement/status, FR/TR/TEST mapping, canonical ID rules `^[A-Z]+-[A-Z0-9]+-\d{3}$` or `ISSUE-\d+`).

Internal checklist state stays local by default. Enable `workflow.todo.internal.enable` only when you want MCP TODOs as the backing store.

## GraphRAG & Workspace

Ad-hoc ingestion and workspace policy helpers are provided via the respective skills.

## Differences from the Original Claude Code Plugin

- Primary interface is Grok `SKILL.md` files (not Claude hooks/skills system).
- Strong emphasis on `pwsh.exe` and the workspace PowerShell modules.
- Bash hooks and `mcpserver-repl` helper usage retained for contract fidelity and multi-agent workflow shim use.
- Cache/ is shipped clean; runtime state lives in the user's environment.
- No assumption of `CLAUDE_PLUGIN_ROOT` or Claude-specific env vars (Grok equivalents are `PLUGIN_ROOT` / `MCP_GROK_*`).

## Development / Validation

- `bats tests/` covers skills content + **bash** Model C smoke (not the live `.ps1` path).
- Prefer a separate Pester / host check for PowerShell hooks when changing `plugin-hook.ps1`.
- Grok-specific validation: load SKILL.md files, confirm `grok mcp doctor mcpserver` against `/mcp-transport`, exercise `mcpserver-repl` / `lib/repl-invoke.ps1`, confirm marker bootstrap + session/turn lifecycle.
- See `Plugin-Validation-Testing-Plan.md` and `lib/GAPS.md`.

## License

MIT (same as source).

---

Maintained as part of the McpServer workspace agent plugin ecosystem. The Grok contract has been registered in `MarkerFileService.BuildDefaultAgentPlugins`. After the next McpServer restart, `AGENTS-README-FIRST.yaml` will include the `Grok` entry and instruct GrokCode agents to bootstrap `mcpserver-grok-plugin` automatically.
