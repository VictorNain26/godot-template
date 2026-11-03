#!/usr/bin/env bash
# Claude Code PostToolUse hook (Edit|Write): parse-check, format-check and lint
# the GDScript file that was just written. Exit 2 sends the errors to Claude.
set -uo pipefail

file=$(jq -r '.tool_input.file_path // empty')
case "$file" in
*.gd) ;;
*) exit 0 ;;
esac

project=${CLAUDE_PROJECT_DIR:-$(pwd)}
cd "$project" || exit 0
rel=${file#"$project"/}
case "$rel" in
/* | addons/*) exit 0 ;;
esac
[ -f "$rel" ] || exit 0

out=$({
	mise run import >/dev/null &&
		godot --headless --path . --log-file "${TMPDIR:-/tmp}/godot-check.log" --check-only -s "$rel" &&
		mise exec -- gdformat --check "$rel" &&
		mise exec -- gdlint "$rel"
} 2>&1)
if [ $? -ne 0 ]; then
	printf '%s\n' "$out" | grep -v -e '^Godot Engine v' -e '^\[import\]' -e '^\s*$' >&2
	exit 2
fi
exit 0
