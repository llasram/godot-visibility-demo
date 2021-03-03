extends "res://addons/gut/test.gd"

const TEST_CASE_DIR := 'res://test/unit/shadow_caster/cases'

func get_cases():
    var cases := []
    var dir := Directory.new()
    assert(dir.open(TEST_CASE_DIR) == OK)
    assert(dir.list_dir_begin(true, true) == OK)
    while true:
        var name := dir.get_next()
        if name == "":
            break
        if dir.current_is_dir():
            continue
        if name.get_extension() != "tscn":
            continue
        cases.append(name)
    return cases

func test_visibility_cases(name: String = use_parameters(get_cases())):
    var path = TEST_CASE_DIR.plus_file(name)
    var tester: VisibilityTester = autofree(load(path).instance())
    var actual := tester.actual_visible()
    var expected := tester.expected_visible()
    assert_eq_shallow(actual, expected)

