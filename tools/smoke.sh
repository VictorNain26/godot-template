#!/usr/bin/env bash
# Run a Godot binary headless for 120 frames; fail on a non-zero exit or any
# error line. Usage: tools/smoke.sh <label> <godot binary> [extra args...]
set -uo pipefail

label=$1
shift
rc=0
out=$(timeout 120 "$@" --headless --log-file "${TMPDIR:-/tmp}/godot-smoke.log" --quit-after 120 2>&1) || rc=$?
errors=$(printf '%s\n' "$out" | grep -E '^(USER )?(SCRIPT )?ERROR' || true)
if [ "$rc" -ne 0 ] || [ -n "$errors" ]; then
	printf 'smoke failed: %s (exit %s)\n%s\n' "$label" "$rc" "$errors" >&2
	exit 1
fi
