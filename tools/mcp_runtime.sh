#!/usr/bin/env bash
# Launch the godot-mcp-runtime MCP server (the "godot-runtime" entry of .mcp.json):
# it runs the game itself, without the editor, and lets an agent capture frames,
# send input actions and read the running scene tree.
#
# The server and its dependencies are pinned, with integrity hashes, by
# tools/mcp_runtime/package-lock.json and installed under .godot/ so that
# neither Godot nor the linters ever scan node_modules.
#
# stdout is the MCP channel: everything this script prints goes to stderr.
set -euo pipefail
cd "$(dirname "$0")/.."

pin=tools/mcp_runtime
dest=.godot/mcp_runtime
server=$dest/node_modules/godot-mcp-runtime/dist/index.js
if [ ! -f "$server" ] || ! cmp -s "$pin/package-lock.json" "$dest/package-lock.json"; then
	mkdir -p "$dest"
	cp "$pin/package.json" "$pin/package-lock.json" "$dest/"
	(cd "$dest" && npm ci --ignore-scripts --no-audit --no-fund) >&2
fi

# A session without a display (cloud session, CI) gets a virtual one, so the
# game can still render and be captured. With a display, use it as is.
if [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
	exec xvfb-run -a -s "-screen 0 1280x720x24" node "$server"
fi
exec node "$server"
