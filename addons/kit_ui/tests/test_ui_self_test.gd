extends GdUnitTestSuite

## The export checks of the kit's menus (KitUiSelfTest) pass on this project,
## and the game's kit config lists the licences of the menus' fonts, which
## the kit's self-test checks in a build. Part of the kit's menus
## (addons/kit_ui).


func test_the_menus_fonts_are_found() -> void:
	assert_array(KitUiSelfTest.run()).is_empty()


func test_the_kit_config_lists_the_licences_of_the_menus_fonts() -> void:
	var listed: Array = KitConfig.constant("LICENCES", [])
	for path: String in UiStyle.LICENCES:
		assert_array(listed).contains([path])
