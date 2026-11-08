---
name: verify
description: Play the game in the running Godot editor through godot-ai to confirm a visible change works - run a scene, drive it with the move_* actions, capture frames, read errors. Use after any change a player could see, and before saying such a change is done.
---

# Verify in the running game

`mise run check` proves the rules and the wiring; this skill proves what a player sees. Every step goes through the godot-ai MCP tools; their parameters come from each tool's schema.

1. **Editor.** Call `editor_state`. If the editor does not answer, ask the user to open it; if the tool is missing, see the `godot-ai-bridge` skill.
2. **Run.** `project_run` in `custom` mode on the scene under test, a `scenes/main_*.tscn`. Its response carries `recent_errors`: any error there ends the run as failed.
3. **Baseline.** `game_manage` op `get_node_info` on the node the change affects (`Player` in the demos): note its position or the property that should change. Take an `editor_screenshot` in `game` mode (its image is kept in the session's tool results; `save_to` is cinematic-only).
4. **Drive.** Send input with `game_manage` op `input_action` (or `input_sequence` for a timed sequence) using only the `move_*` actions of `project.godot`, never raw keys. Hold an action for several frames, not one.
5. **Observe.** Read the same node again and take screenshots over several frames. The change is confirmed only if the observed value moves the way the change says (e.g. `move_right` → `position.x` grows) and the frames show it.
6. **Errors.** `logs_read`: any `ERROR`, `SCRIPT ERROR` or `USER ERROR` line since the run started fails the verification, even if the behaviour looked right.
7. **Stop** the game, then report: scene, inputs sent, values before and after, screenshot paths, errors found.
