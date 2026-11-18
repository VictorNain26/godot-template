class_name ErrorLog
extends Logger
## Keeps every engine error printed from start-up on (script, shader and
## engine errors; warnings are left out), so the export self-test can fail on
## one even when nothing it checks broke: a script left out of the build
## makes another fail to compile, and the game goes on without it. Started
## by Prefs before it reads the kit config, only under `-- --selftest`.
## Part of the kit (addons/kit).

static var _log: ErrorLog

var _errors: Array[String] = []
var _lock := Mutex.new()


## Starts keeping errors, once.
static func start() -> void:
	if _log == null:
		_log = ErrorLog.new()
		OS.add_logger(_log)


## The errors kept since start(), oldest first.
static func errors() -> Array[String]:
	if _log == null:
		return []
	_log._lock.lock()
	var out := _log._errors.duplicate()
	_log._lock.unlock()
	return out


# Called by the engine, from any thread.
func _log_error(
	function: String,
	file: String,
	line: int,
	code: String,
	rationale: String,
	_editor_notify: bool,
	error_type: int,
	_script_backtraces: Array[ScriptBacktrace]
) -> void:
	if error_type == ERROR_TYPE_WARNING:
		return
	var what := rationale if rationale != "" else code
	_lock.lock()
	_errors.append("%s (%s:%d, %s)" % [what, file, line, function])
	_lock.unlock()
