#!/usr/bin/env sh
# Print the pinned Godot's version as its export templates folder names it:
# "4.7.2.stable" for "4.7.2.stable.official.<hash>", "4.8.stable" for an x.y.0
# release printed as "4.8.stable.official.<hash>".
set -eu
godot --version | grep -oE '^[0-9]+(\.[0-9]+)+\.[a-z0-9]+'
