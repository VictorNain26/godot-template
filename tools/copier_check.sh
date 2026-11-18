#!/usr/bin/env bash
# Proves the Copier set-up (copier.yml) does what it promises, on the
# template as it stands in this folder:
#   1. `copier copy` makes a game that passes its own `mise run check`;
#   2. the game changes its name, its code and its config, and deletes a file
#      of the base (.editorconfig);
#   3. the template changes the same files, and the kit;
#   4. `copier update` brings the kit and project.godot's new line into the
#      game, keeps the game's name, code and config as they were, does not
#      bring back the deleted file, leaves no conflict, and the game still
#      passes `mise run check`.
#   tools/copier_check.sh        (mise run copier-check)
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export GIT_AUTHOR_NAME=check GIT_AUTHOR_EMAIL=check@example.invalid
export GIT_COMMITTER_NAME=check GIT_COMMITTER_EMAIL=check@example.invalid
step() { echo "copier-check: $1"; }
fail() {
	echo "COPIER CHECK FAILED: $1" >&2
	exit 1
}

# The template as it stands: tracked and new files, not what git ignores.
step "template v1"
mkdir "$tmp/tpl"
(cd "$here" && git ls-files -co --exclude-standard -z | xargs -0 -I{} cp --parents {} "$tmp/tpl/")
git -C "$tmp/tpl" init -q -b main
git -C "$tmp/tpl" add -A
git -C "$tmp/tpl" commit -qm "template v1"

step "copier copy"
copier copy --quiet --defaults --vcs-ref HEAD "$tmp/tpl" "$tmp/game" >/dev/null
cd "$tmp/game"
grep -q '^_commit:' .copier-answers.yml || fail "no _commit in .copier-answers.yml"
grep -q '^_src_path:' .copier-answers.yml || fail "no _src_path in .copier-answers.yml"
[ ! -e copier.yml ] || fail "copier.yml was copied into the game"
for path in addons/kit/README.md addons/kit_ui/README.md kit_config.gd src/player_motion.gd .editorconfig; do
	[ -e "$path" ] || fail "$path missing from the new game"
done
git init -q -b main
git add -A
git commit -qm "game from the template"
mise trust -q mise.toml >/dev/null 2>&1 || true
step "the new game's check"
mise run check >"$tmp/check1.log" 2>&1 || {
	tail -30 "$tmp/check1.log"
	fail "the new game does not pass mise run check"
}

step "the game makes itself its own"
sed -i 's/^config\/name=.*/config\/name="Banc"/' project.godot
echo "# the game's own line" >>src/player_motion.gd
echo "# the game's own config line" >>kit_config.gd
git rm -q .editorconfig
git commit -qam "the game's changes"

step "template v2"
cd "$tmp/tpl"
echo "Template v2 line." >>addons/kit/README.md
echo "# template v2 line" >>src/player_motion.gd
echo "# template v2 config line" >>kit_config.gd
echo "# template v2" >>.editorconfig
grep -q '^gdscript/warnings/return_value_discarded=0$' project.godot || fail "project.godot changed: update this check"
sed -i 's/^gdscript\/warnings\/return_value_discarded=0$/gdscript\/warnings\/return_value_discarded=1/' project.godot
git commit -qam "template v2"

step "copier update"
cd "$tmp/game"
copier update --quiet --defaults --vcs-ref HEAD --conflict inline >/dev/null
if git grep -nE '^(<<<<<<<|>>>>>>>)' -- . >/dev/null; then
	git grep -nE '^(<<<<<<<|>>>>>>>)' -- . | head
	fail "the update left conflicts"
fi
grep -q '^Template v2 line\.$' addons/kit/README.md || fail "the kit's change did not reach the game"
grep -q '^gdscript/warnings/return_value_discarded=1$' project.godot || fail "project.godot's new line did not reach the game"
grep -q '^config/name="Banc"$' project.godot || fail "the update changed the game's name"
grep -q "^# the game's own line$" src/player_motion.gd || fail "the update lost the game's code"
! grep -q '^# template v2 line$' src/player_motion.gd || fail "the update wrote into the game's code"
grep -q "^# the game's own config line$" kit_config.gd || fail "the update lost the game's config"
! grep -q '^# template v2 config line$' kit_config.gd || fail "the update wrote into the game's config"
[ ! -e .editorconfig ] || fail "the update brought back a file the game deleted"
git add -A
git commit -qm "template update"

step "the updated game's check"
# The template v2 made return_value_discarded a warning, not an error:
# the check must still pass.
mise run check >"$tmp/check2.log" 2>&1 || {
	tail -30 "$tmp/check2.log"
	fail "the updated game does not pass mise run check"
}
echo "COPIER CHECK OK"
