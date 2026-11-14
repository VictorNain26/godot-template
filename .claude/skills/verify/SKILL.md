---
name: verify
description: Play the game to confirm a visible change works - in the running Godot editor through godot-ai, or without the editor through godot-runtime - run a scene, drive it with the move_* actions, capture frames, read errors. Use after any change a player could see, and before saying such a change is done.
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

## Without the editor

In a cloud session, or when the Windows editor cannot be opened, run the same check through the `godot-runtime` MCP server. It launches the game itself, under a virtual display when the machine has none, instead of driving the editor. The steps above keep their meaning; only the tools change:

- **Run and stop.** `run_project` with `projectPath` (the repository root) and `scene`; `stop_project` at the end.
- **Read a node.** `run_script`. The project treats GDScript warnings as errors, so the script must be fully typed: cast the node before reading it.

  ```gdscript
  extends RefCounted


  func execute(scene_tree: SceneTree) -> Variant:
  	var player := scene_tree.current_scene.get_node("Player") as Node2D
  	return player.position
  ```

- **Drive.** `simulate_input` with actions, e.g. `{"type": "action", "action": "move_right", "hold_ms": 600}`.
- **Frames.** `take_screenshot` returns the path of a PNG under `.mcp/`: open it with Read. A screenshot that was not read confirms nothing.
- **Errors.** `get_debug_output`. An `init_output_device` or ALSA error only means the machine has no sound card; any other `ERROR` line fails the verification.

Say in the report which path was used. This one runs the Linux build under software rendering: it confirms behaviour and layout, not Windows-specific rendering or performance.
