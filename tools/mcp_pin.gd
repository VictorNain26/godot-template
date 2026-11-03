class_name McpPin
extends RefCounted

## Checks that the godot-ai entry of a .mcp.json launches the server version and
## dependency cutoff pinned by the bundled addon's plugin.cfg.

const SERVER := "godot-ai"


static func problems(mcp_json: String, version: String, cutoff: String) -> PackedStringArray:
	# JSON.parse, unlike JSON.parse_string, reports a syntax error without logging it.
	var json := JSON.new()
	var parsed: Variant = json.data if json.parse(mcp_json) == OK else null
	if not parsed is Dictionary:
		return PackedStringArray([".mcp.json is missing or is not a JSON object"])
	var root: Dictionary = parsed
	var servers_value: Variant = root.get("mcpServers")
	var servers: Dictionary = servers_value if servers_value is Dictionary else {}
	if not servers.has(SERVER):
		return PackedStringArray(["mcpServers has no %s entry" % SERVER])
	var entry_value: Variant = servers[SERVER]
	var entry: Dictionary = entry_value if entry_value is Dictionary else {}
	var args_value: Variant = entry.get("args")
	var args: Array = args_value if args_value is Array else []
	var found := PackedStringArray()
	var package := "%s==%s" % [SERVER, version]
	if not args.has(package):
		found.append("args do not pin %s" % package)
	var at := args.find("--exclude-newer")
	if at < 0 or at + 1 >= args.size() or args[at + 1] != cutoff:
		found.append("args do not pin --exclude-newer %s" % cutoff)
	return found
