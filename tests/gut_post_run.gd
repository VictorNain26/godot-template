extends GutHookScript

# GUT exits 0 when a test script fails to parse: it skips the script with a
# warning and reports "Nothing was run". Fail the run instead.

const GutLogger := preload("res://addons/gut/logger.gd")


func run() -> void:
	var main: GutMain = gut
	var logger: GutLogger = main.logger
	var errors: Array = logger.get_errors()
	var warnings: Array = logger.get_warnings()
	var test_count: int = main.get_test_count()
	if errors.size() + warnings.size() > 0 or test_count == 0:
		set_exit_code(1)
