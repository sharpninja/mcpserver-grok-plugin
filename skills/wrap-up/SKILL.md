---
name: wrap-up
description: Close out MCP-backed Grok work when asked to "wrap up", "export requirements", or "close out".
---

Trust marker details only after the local status script confirms marker trust and workspace health. Use `lib/repl-invoke.ps1` or `lib/repl-invoke.ps1`; do not use raw REST for normal MCP mutations.

`workflow.sessionlog.*`, `workflow.todo.*`, and `workflow.requirements.*` are plugin shim/REPL method names. They are not expected to appear as literal Grok `search_tool` results. Grok MCP discovery should expose native MCP names such as `sessionlog_submit`, `todo_list`, and `requirements_generate`. If Grok exposes only `pwsh`, invoke the plugin shim through `pwsh.exe -NoProfile -NonInteractive -File "$env:GROK_PLUGIN_ROOT\lib\repl-invoke.ps1" -Method <workflow.method> -ParamsYaml <yaml>` rather than declaring the plugin unavailable solely because workflow names are absent from tool discovery.

Reconcile requirements through `workflow.requirements.*`, export wiki documents with `workflow.requirements.generateDocument`, run validation, then use the `commit-sync` pause contract for commit/push. Reconcile the session log with `workflow.sessionlog.appendDialog` and `workflow.sessionlog.appendActions`.

Complete the turn with `workflow.sessionlog.completeTurn`. Use `workflow.sessionlog.failTurn` for validation failure, export failure, or blocked commit/push.
