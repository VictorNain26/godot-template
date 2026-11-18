#!/usr/bin/env bash
# Run GdUnit4 headless on the given test directories (default: the game's
# tests and the kit's), print only what matters, keep the exit code.
#   tools/gdunit.sh                       every test
#   tools/gdunit.sh res://tests/test_x.gd one file
set -uo pipefail
# By default: the game's tests, the kit's, and those of every kit_* addon kept
# (the kit's menus, addons/kit_ui, may be deleted by a game that has its own).
defaults=(res://tests res://addons/kit/tests)
for dir in addons/kit_*/tests; do
	[ -d "$dir" ] && defaults+=("res://$dir")
done
args=()
for target in "${@:-${defaults[@]}}"; do
	for t in $target; do args+=(-a "$t"); done
done
rm -rf reports
mkdir -p .godot
out=$(timeout 600 godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
	"${args[@]}" --ignoreHeadlessMode -c 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
code=${PIPESTATUS[0]}
printf '%s\n' "$out" > .godot/gdunit.log
printf '%s\n' "$out" | grep -E "FAILED|Report:|Expecting|but |at '|Timeout|Overall Summary|Parse Error|SCRIPT ERROR" | head -80
if [ "$code" -ne 0 ]; then
	echo "tests failed (exit $code); full log in .godot/gdunit.log, report in reports/" >&2
fi
exit "$code"
