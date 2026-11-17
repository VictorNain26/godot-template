#!/usr/bin/env bash
# Claude Code Stop hook: Claude does not end a turn on a project that no
# longer lints or compiles.
#
# When game files differ from the last state that passed, this runs
# `mise run lint` and `mise run validate` (a few seconds, the import is
# skipped when nothing was added). On failure it exits 2: Claude Code keeps
# Claude working and shows it the output. The post-edit hook only sees the
# .gd file just written; this one also catches a scene, a resource or
# project.godot changed by godot-ai or by a script. Tests and the scene smoke
# run stay in `mise run check` and in CI: too slow for every turn end.
#
# No stop_hook_active guard on purpose: with one, the second stop attempt
# would pass on a project that still fails. Claude Code itself stops honouring
# a Stop hook after several consecutive blocks.
set -uo pipefail
cat >/dev/null
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
command -v mise >/dev/null 2>&1 || exit 0
mise exec -- godot --version >/dev/null 2>&1 || exit 0 # no engine here: nothing to run
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

patterns=('*.gd' '*.tscn' '*.tres' '*.gdshader' 'project.godot' 'gdlintrc')
state="$({
	git diff HEAD -- "${patterns[@]}"
	git ls-files --others --exclude-standard -- "${patterns[@]}" | xargs -r cat
} 2>/dev/null | cksum)"
stamp=".godot/claude-stop.stamp"
[ "$state" = "$(cksum </dev/null)" ] && exit 0                # nothing changed since the last commit
[ -f "$stamp" ] && [ "$(cat "$stamp")" = "$state" ] && exit 0 # this exact state already passed

if output="$(mise run lint 2>&1 && mise run validate 2>&1)"; then
	mkdir -p .godot && printf '%s' "$state" >"$stamp"
	exit 0
fi
{
	echo "mise run lint / mise run validate fail on your changes. Fix the cause before finishing:"
	printf '%s\n' "$output" | grep -v -e 'Godot Engine v' -e '^\s*$' | tail -40
} >&2
exit 2
