#!/usr/bin/env bash
# Runs the testdata cases of a challenge against a solution, in any language.
#
# Usage: scripts/run-tests.sh <solution-dir> [level]
#
# The solution dir must be named after the challenge (for example
# solutions/guiferpa/001-log-parser) and contain a manifest.json:
#
#   { "build": "optional command run once", "command": "command that runs the solution" }
#
# For each case, the runner starts the command once, writes one JSON operation
# per line to its stdin and reads one JSON result per line from its stdout.
# See testdata/README.md for the protocol.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "error: $*" >&2; exit 2; }

[ $# -ge 1 ] || { echo "usage: $0 <solution-dir> [level]" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || fail "jq is required: https://jqlang.org/download/"

SOLUTION="$(cd "$1" 2>/dev/null && pwd)" || fail "'$1' is not a directory"
LEVEL="${2:-}"
CHALLENGE="$(basename "$SOLUTION")"
TESTDATA="$ROOT/testdata/$CHALLENGE"
MANIFEST="$SOLUTION/manifest.json"

[ -d "$TESTDATA" ] || fail "no test data for '$CHALLENGE' (expected $TESTDATA)"
[ -f "$MANIFEST" ] || fail "manifest not found: $MANIFEST"
COMMAND="$(jq -er '.command // empty' "$MANIFEST")" || fail "manifest.json must have a \"command\""
BUILD="$(jq -r '.build // empty' "$MANIFEST")"

if [ -n "$LEVEL" ]; then
  FILES="$TESTDATA/level-$LEVEL.json"
  [ -f "$FILES" ] || fail "no level $LEVEL for '$CHALLENGE'"
else
  FILES="$(ls "$TESTDATA"/level-*.json | sort)"
fi

if [ -n "$BUILD" ]; then
  echo "build: $BUILD"
  (cd "$SOLUTION" && sh -c "$BUILD") || { echo "build failed" >&2; exit 1; }
fi

STDERR_FILE="$(mktemp)"
trap 'rm -f "$STDERR_FILE"' EXIT

TOTAL_PASS=0
TOTAL_FAIL=0

for FILE in $FILES; do
  LEVEL_NUM="$(jq -r '.level' "$FILE")"
  COUNT="$(jq '.cases | length' "$FILE")"
  PASS=0
  echo
  echo "$CHALLENGE — level $LEVEL_NUM"

  i=0
  while [ "$i" -lt "$COUNT" ]; do
    NAME="$(jq -r --argjson i "$i" '.cases[$i].name' "$FILE")"
    INPUT="$(jq -c --argjson i "$i" '.cases[$i]
      | (if has("setup") then {op: "setup", args: .setup} else empty end),
        (.operations[] | {op, args})' "$FILE")"

    OUTPUT="$(printf '%s\n' "$INPUT" | (cd "$SOLUTION" && sh -c "$COMMAND") 2>"$STDERR_FILE")"
    STATUS=$?

    if [ "$STATUS" -ne 0 ]; then
      REPORT="  the program exited with status $STATUS"
    elif ! GOT="$(printf '%s\n' "$OUTPUT" | jq -s -c '.' 2>/dev/null)"; then
      REPORT="  the output is not valid JSON lines:
$(printf '%s\n' "$OUTPUT" | sed 's/^/    | /')"
    else
      REPORT="$(jq -r --argjson i "$i" --argjson got "$GOT" '
        .cases[$i] as $c
        | ($got | if $c | has("setup") then .[1:] else . end) as $got
        | ($c.operations | length) as $n
        | if ($got | length) != $n then
            "  expected \($n) output lines, got \($got | length)"
          else
            [range(0; $n) as $k
             | $c.operations[$k]
             | select(has("expected") and .expected != $got[$k])
             | "  #\($k) \(.op) \(.args | tojson)\n    expected: \(.expected | tojson)\n    got:      \($got[$k] | tojson)"]
            | join("\n")
          end' "$FILE")"
    fi

    if [ -z "$REPORT" ]; then
      PASS=$((PASS + 1))
      echo "  PASS  $NAME"
    else
      echo "  FAIL  $NAME"
      echo "$REPORT" | sed 's/^/    /'
      if [ -s "$STDERR_FILE" ]; then
        echo "      stderr:"
        tail -n 5 "$STDERR_FILE" | sed 's/^/      | /'
      fi
    fi
    i=$((i + 1))
  done

  echo "  $PASS/$COUNT cases passed"
  TOTAL_PASS=$((TOTAL_PASS + PASS))
  TOTAL_FAIL=$((TOTAL_FAIL + COUNT - PASS))
done

echo
if [ "$TOTAL_FAIL" -eq 0 ]; then
  echo "OK: all $TOTAL_PASS cases passed"
else
  echo "FAILED: $TOTAL_FAIL of $((TOTAL_PASS + TOTAL_FAIL)) cases failed"
  exit 1
fi
