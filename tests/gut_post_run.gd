extends GutHookScript

# GUT exits 0 when a test script fails to parse: it skips the script with a
# warning and reports "Nothing was run". Fail the run instead.


func run() -> void:
	var problems: int = gut.logger.get_errors().size() + gut.logger.get_warnings().size()
	if problems > 0 or gut.get_test_count() == 0:
		set_exit_code(1)
