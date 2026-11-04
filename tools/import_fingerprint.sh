#!/usr/bin/env sh
# Print what a Godot import depends on: the project file list (an added or
# removed file), the mtime of each imported asset (its sibling .import file)
# and the global-class lines of each script (the class_name cache). Body-only
# script edits and scene edits leave it unchanged, so they skip the import.
set -u

files() { find . -path './.*' -prune -o -path ./build -prune -o -type f "$@" -print | LC_ALL=C sort; }

files
files -name '*.import' | while IFS= read -r f; do
	stat -c '%Y %n' "${f%.import}" 2>/dev/null || true
done
files -name '*.gd' | while IFS= read -r f; do
	grep -HE '^(class_name|extends|@icon|@abstract)' "$f" || true
done
