# McpServer Grok Plugin - Enforcement Protocol (v4)

This plugin implements the McpServer **v4 Shared Enforcement Protocol** for Grok agent sessions.

## Shared Core Reference

All enforcement behaviors align with the canonical v4 shared core defined in:
- `packages/mcpserver-agent-core` (`@sharpninja/mcpserver-agent-core`)
- `docs/plans/plan-agent-plugin-operational-parity-v1.0.md` in the McpServer repository
- TR-MCP-AGENT-PARITY-010 through -013 (technical requirements for shared enforcement)

## Three-Phase Protocol

Every user message triggers the v4 three-phase enforcement protocol.

**Production Grok wiring** is PowerShell: `hooks/hooks.json` invokes
`hooks/scripts/*.ps1` → `lib/plugin-hook.ps1` (requires `pwsh`). Bash
`hooks/scripts/*.sh` wrappers remain for Model C / multi-host portability and
BATS smoke; they are **not** the live Grok host entrypoints unless
`hooks.json` is changed. Shipped bash wrappers: `session-start.sh`,
`user-prompt-submit.sh`, `code-verify.sh`, `plan-approved.sh`,
`plan-modified.sh`, and `stop-gate.sh` (thin sources of `plugin-env.sh` +
`hook-lib.sh`). Other hook names exist as `*_main` functions in
`lib/hook-lib.sh` only. See `lib/GAPS.md` for dual-stack deltas.

### Phase 1 - Begin Turn (`UserPromptSubmit` hook)
- **Production:** `hooks/scripts/user-prompt-submit.ps1` → `plugin-hook.ps1` opens the turn (dedupe, fail-closed statuses when begin fails)
- **Portable/Model C:** `hooks/scripts/user-prompt-submit.sh` → `hook-lib.sh` `user_prompt_submit_main` (bash degrade path exercised by `tests/smoke.bats`)
- A `current-turn.yaml` file is written to the workspace cache so the Stop hook can verify completion
- If the server is unavailable, the turn is buffered to the v4 failsafe cache

### Phase 2 - Edit + Verify (`PostToolUse` hook on Write/Edit)
- **Production:** `hooks/scripts/code-verify.ps1` (and plan hooks) via `plugin-hook.ps1`
- **Portable/Model C:** `hooks/scripts/code-verify.sh` / `plan-modified.sh` / `plan-approved.sh` → `hook-lib.sh` (`code_verify_main`, `plan_modified_main`, `plan_approved_main`)
- Build failure transitions the enforcement state to `BlockedOnBuild`
- Build success is recorded in the session log action list (`appendActions`)

### Phase 3 - Complete Turn (`Stop` hook)
- **Production:** `hooks/scripts/stop-gate.ps1` via `plugin-hook.ps1`
- **Portable/Model C:** `hooks/scripts/stop-gate.sh` → `hook-lib.sh` `stop_gate_main`
- Verifies the turn was begun and not left open
- If a prior build failed, the stop gate blocks the response (no escape hatch)
- Successful completion calls `workflow.sessionlog.completeTurn`
- If server is unavailable, the completion is buffered to failsafe cache

## State Machine

The enforcement states (per v4 shared core, TR-MCP-AGENT-PARITY-011):

```
NoTurn
  |-- UserPromptSubmit --> TurnOpen
       |-- Write/Edit (success) --> EditsInProgress
       |-- Write/Edit (failure) --> BlockedOnBuild (no escape, stop gate blocked)
       |-- Stop (all builds green) --> TurnComplete
       |-- Stop (pending edits, no complete) --> BlockedOnMissingComplete
```

## Failsafe Cache (v4 format, TR-MCP-AGENT-PARITY-013)

When the MCP server is unavailable, pending REPL calls are buffered to the workspace failsafe cache:

**v4 layout:** `<workspace_root>/.mcpServer/failsafe/GrokCode/workspaces/<base64url(workspacePath)>/`
- `pending/` - queued entries, max 3 retries
- `failed/` - entries exceeding retry limit

The workspace key is the Base64URL encoding of the absolute workspace path, matching
`V4CacheManager.GetScopedCachePath` in `@sharpninja/mcpserver-agent-core`.

**Legacy layout** (pre-v4): `cache/workspaces/<slug-sha1>/sessions/<session-key>/` remains
supported for read-back during migration. New writes use the v4 layout.

## Marker Bootstrap (TR-MCP-AGENT-PARITY-012)

`lib/marker-resolver.sh` (and `lib/marker-resolver.ps1`) implements upward directory search for
`AGENTS-README-FIRST.yaml`, HMAC-SHA256 signature verification with the workspace API key, and
nonce health challenge against `/health?nonce=`. Behavior is identical to `V4MarkerTrustService`
in the shared core.

## Plugin Version

This plugin is on the v1.x operational parity release line. All eight official `mcpserver-*-plugin`
repositories share this enforcement protocol version.

## Agent Identity

This plugin targets the `GrokCode` agent (`sourceType: GrokCode`). Session IDs use the prefix
`GrokCode-<yyyyMMddTHHmmssZ>-<suffix>`. The required env var is `GROK_PLUGIN_ROOT`.

## References

- `hooks/hooks.json` - **production** lifecycle wiring (pwsh → `*.ps1`)
- `hooks/scripts/*.sh` - Model C / portable bash thin shims (see `tests/smoke.bats`)
- `lib/GAPS.md` - intentional PowerShell vs bash dual-stack gaps
- `lib/cache-scope.sh` - workspace key derivation (v4 failsafe helpers; runtime CACHE_DIR is flat agent root)
- `lib/cache-manager.sh` - pending write/flush/recovery (MAX_RETRIES=3)
- `lib/marker-resolver.sh` - HMAC-SHA256 marker trust (bash)
- `lib/marker-resolver.ps1` - HMAC-SHA256 marker trust (PowerShell)
- `lib/repl-invoke.sh` - REPL client with retry and timeout
- `Plugin-Validation-Testing-Plan.md` - parity v1 validation checklist
