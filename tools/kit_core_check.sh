#!/usr/bin/env bash
# Proves the kit (addons/kit) works for a game that deleted the kit's menus
# (addons/kit_ui) and wrote its own: builds such a game in a scratch folder
# from tools/kit_core_fixture, the kit and GdUnit4, then runs on it what a
# game runs: import, compile every file, the kit's tests, the self-test, and
# real clicks on the game's own menu under Xvfb (skipped without xvfb-run).
#   tools/kit_core_check.sh        (mise run kit-core-check)
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/addons" "$tmp/tools"
cp -r "$here/addons/kit" "$here/addons/gdUnit4" "$tmp/addons/"
cp "$here/tools/validate.gd" "$here/tools/gdunit.sh" "$tmp/tools/"
(cd "$here/tools/kit_core_fixture" && tar --exclude=.gdignore -cf - .) | (cd "$tmp" && tar -xf -)
# The template's settings (warnings as errors, input actions, French
# fallback), without its menus, its fonts or the editor bridge.
python3 - "$here/project.godot" "$tmp/project.godot" <<'PY'
import re, sys
s = open(sys.argv[1]).read()
s = s.replace('run/main_scene="res://scenes/title.tscn"', 'run/main_scene="res://scenes/own_menu.tscn"')
s = re.sub(r'(?m)^_mcp_game_helper=.*\n', '', s)
s = re.sub(r'(?m)^enabled=PackedStringArray\(.*\)\n', 'enabled=PackedStringArray("res://addons/gdUnit4/plugin.cfg")\n', s)
s = re.sub(r'(?m)^theme/custom_font=.*\n', '', s)
s = re.sub(r'(?m)^locale/translations=.*\n', 'locale/translations=PackedStringArray("res://locale/en.po")\n', s)
for needed in ('kit_ui', 'godot_ai', 'title.tscn'):
    if needed in s:
        sys.exit("project.godot still names " + needed)
open(sys.argv[2], 'w').write(s)
PY
cd "$tmp"
step() { echo "kit-core-check: $1"; }
step import
timeout 300 godot --headless --import >/dev/null 2>&1 || true
step validate
timeout 300 godot --headless -s res://tools/validate.gd 2>&1 | grep -E "validate:|SCRIPT ERROR"
[ "${PIPESTATUS[0]}" -eq 0 ]
step tests
tools/gdunit.sh res://addons/kit/tests
step self-test
out=$(timeout 300 godot --headless -- --selftest 2>&1 || true)
printf '%s\n' "$out" | grep -E "SELFTEST"
printf '%s\n' "$out" | grep -q "SELFTEST OK"
if command -v xvfb-run >/dev/null 2>&1; then
	step mouse-check
	out=$(timeout 600 xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 res://addons/kit/dev/mouse_check.tscn 2>&1 || true)
	printf '%s\n' "$out" | grep -E "MOUSE CHECK"
	printf '%s\n' "$out" | grep -q "MOUSE CHECK OK"
else
	step "mouse-check skipped: no xvfb-run"
fi
echo "KIT CORE CHECK OK"
