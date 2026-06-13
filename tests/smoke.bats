#!/usr/bin/env bats
# smoke.bats - Model C per-repo migration smoke test.
#
# Proves the migrated host wrappers wire up to the canonical synced lib
# (lib/plugin-env.sh + lib/hook-lib.sh) and emit schema-valid output even when
# NO McpServer marker is reachable. This is the thin hook smoke test required
# by VALIDATION MODEL C: the shared-lib behavior itself is proven by the core
# fixtures, so here we only assert the wrappers load the core and degrade
# gracefully (exit 0 + valid JSON) with no network and no marker.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

    # Wrapper placement: grok is a claude-family host (hooks/scripts/).
    SESSION_START="$REPO_ROOT/hooks/scripts/session-start.sh"
    USER_PROMPT_SUBMIT="$REPO_ROOT/hooks/scripts/user-prompt-submit.sh"

    # Isolated HOME + cwd with no AGENTS-README-FIRST.yaml so marker resolution
    # fails, and a throwaway PLUGIN_ROOT_OVERRIDE so the cache lands in a temp
    # dir (never the real repo cache/).
    ISO_HOME="$(mktemp -d)"
    ISO_CWD="$(mktemp -d)"
    export PLUGIN_ROOT_OVERRIDE="$(mktemp -d)"
}

teardown() {
    rm -rf "$ISO_HOME" "$ISO_CWD" "$PLUGIN_ROOT_OVERRIDE"
}

# Run a wrapper in the isolated, marker-less environment with empty stdin.
run_wrapper() {
    run env HOME="$ISO_HOME" bash -c "cd '$ISO_CWD' && bash '$1' </dev/null"
}

assert_valid_json() {
    printf '%s' "$1" | node -e 'JSON.parse(require("fs").readFileSync(0))'
}

@test "migrated wrappers exist as thin shims onto the canonical core" {
    [ -f "$SESSION_START" ]
    [ -f "$USER_PROMPT_SUBMIT" ]
    # Both must source the synced core, not per-repo lib internals.
    grep -q 'lib/hook-lib.sh' "$SESSION_START"
    grep -q 'lib/plugin-env.sh' "$SESSION_START"
    grep -q 'lib/hook-lib.sh' "$USER_PROMPT_SUBMIT"
    grep -q 'lib/plugin-env.sh' "$USER_PROMPT_SUBMIT"
}

@test "session-start wrapper: exit 0 and valid JSON with no marker" {
    run_wrapper "$SESSION_START"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    assert_valid_json "$output"
}

@test "user-prompt-submit wrapper: exit 0 and valid JSON with no marker" {
    run_wrapper "$USER_PROMPT_SUBMIT"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    assert_valid_json "$output"
}
