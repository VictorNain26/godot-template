#!/usr/bin/env bash
# Claude Code PostToolUse hook (Edit|Write): compile the GDScript file that was
# just written (with the project's autoloads registered, see tools/check_script.gd),
# then format-check and lint that file. Exit 2 sends errors to Claude.
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
case "$rel" in
/* | addons/*) exit 0 ;;
esac
[ -f "$rel" ] || exit 0

out=$({
	mise run import &&
		godot --headless --path . --log-file "$project/.godot/godot-check.log" -s tools/check_script.gd -- "$rel" &&
		mise exec -- gdformat --check "$rel" &&
		mise exec -- gdlint "$rel"
} 2>&1)
if [ $? -ne 0 ]; then
	printf '%s\n' "$out" | grep -v -e 'Godot Engine v' -e '^\s*$' >&2
	exit 2
fi
exit 0
