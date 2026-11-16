#!/usr/bin/env bash
# Claude Code PostToolUse hook (Edit|Write): compile the project's scripts
# with the autoloads registered (tools/validate.gd: `--check-only` reports
# false errors for any script that uses an autoload), then format-check and
# lint the file just written. Exit 2 sends errors to Claude.
set -uo pipefail

project=${CLAUDE_PROJECT_DIR:-$(pwd)}
cd "$project" || exit 2

if ! file=$(mise exec -- jq -er '.tool_input.file_path // ""'); then
	echo "post_edit_gd.sh: could not read tool_input.file_path (is jq installed? run mise install)" >&2
	exit 2
fi
case "$file" in
*.gd) ;;
*) exit 0 ;;
esac

rel=${file#"$project"/}
# Vendored addons are not ours to lint; the kit is.
case "$rel" in
/* | addons/gdUnit4/* | addons/godot_ai/*) exit 0 ;;
esac
[ -f "$rel" ] || exit 0

out=$({
	mise run import &&
		mise exec -- godot --headless --path . --log-file "$project/.godot/godot-check.log" -s res://tools/validate.gd &&
		mise exec -- gdformat --check "$rel" &&
		mise exec -- gdlint "$rel"
} 2>&1)
if [ $? -ne 0 ]; then
	printf '%s\n' "$out" | grep -v -e 'Godot Engine v' -e '^\s*$' >&2
	exit 2
fi
exit 0
