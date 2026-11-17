extends GdUnitTestSuite

# The committed .mcp.json launches the godot-ai server; it must pin the same
# version and dependency cutoff as the bundled addon, or the server and the
# editor plugin drift apart after an addon update.

const MCP_JSON := "res://.mcp.json"
const PLUGIN_CFG := "res://addons/godot_ai/plugin.cfg"
const VERSION := "4.4.0"
const CUTOFF := "2026-11-01T19:00:00Z"


func _mcp(args: Array) -> String:
	return JSON.stringify({"mcpServers": {"godot-ai": {"command": "uvx", "args": args}}})


func _pinned_args(version: String, cutoff: String) -> Array:
	return [
		"--exclude-newer",
		cutoff,
		"--from",
		"godot-ai==%s" % version,
		"godot-ai",
		"attach",
	]


func test_matching_pins_have_no_problem() -> void:
	var text := _mcp(_pinned_args(VERSION, CUTOFF))
	assert_array(McpPin.problems(text, VERSION, CUTOFF)).is_empty()


func test_other_version_is_reported() -> void:
	var text := _mcp(_pinned_args("4.3.0", CUTOFF))
	var found := McpPin.problems(text, VERSION, CUTOFF)
	assert_int(found.size()).is_equal(1)
	assert_str(found[0]).contains("godot-ai==4.4.0")


func test_other_cutoff_is_reported() -> void:
	var text := _mcp(_pinned_args(VERSION, "2026-10-01T00:00:00Z"))
	var found := McpPin.problems(text, VERSION, CUTOFF)
	assert_int(found.size()).is_equal(1)
	assert_str(found[0]).contains(CUTOFF)


func test_missing_server_entry_is_reported() -> void:
	var text := JSON.stringify({"mcpServers": {"blender": {"command": "uvx", "args": []}}})
	var found := McpPin.problems(text, VERSION, CUTOFF)
	assert_int(found.size()).is_equal(1)
	assert_str(found[0]).contains("godot-ai")


func test_invalid_json_is_reported() -> void:
	assert_int(McpPin.problems("{not json", VERSION, CUTOFF).size()).is_equal(1)


func test_missing_file_is_reported() -> void:
	assert_int(McpPin.problems("", VERSION, CUTOFF).size()).is_equal(1)


func test_committed_mcp_json_matches_bundled_addon() -> void:
	var cfg := ConfigFile.new()
	assert_int(cfg.load(PLUGIN_CFG)).is_equal(OK)
	var text := FileAccess.get_file_as_string(MCP_JSON)
	var found := McpPin.problems(
		text,
		str(cfg.get_value("plugin", "version", "")),
		str(cfg.get_value("plugin", "dependency_cutoff", ""))
	)
	(
		assert_array(found)
		. override_failure_message(
			(
				"Emptied by the dock's Configure? git restore .mcp.json. After an addon"
				+ " update, copy the dock's Run this manually args (.claude/skills/godot-ai-bridge/SKILL.md)"
			)
		)
		. is_empty()
	)
