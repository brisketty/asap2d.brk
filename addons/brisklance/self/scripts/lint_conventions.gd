extends SceneTree
## Convention lint for the framework's own GDScript. Flags the CLAUDE.md
## violations that the compiler / warnings-as-errors do NOT catch:
##   - `$` node access and `get_node(` / `get_node_or_null(`
##   - `_`-prefixed private methods (Godot virtuals are allowed)
##
## Run: godot --headless --script res://addons/brisklance/self/scripts/lint_conventions.gd
## Exits non-zero on any violation. CI runs this.

const LINT_ROOTS: PackedStringArray = ["res://addons/brisklance/self/scripts", "res://addons/brisklance/self/autoloads", "res://addons/brisklance/self/prefabs", "res://addons/brisklance/self/scenes"]
const SCRIPT_EXTENSION := ".gd"
## This file necessarily contains `$` / `get_node` as regex string literals.
const SELF_PATH := "res://addons/brisklance/self/scripts/lint_conventions.gd"

## `func _x()` names that are engine callbacks, not private methods.
const ALLOWED_VIRTUALS: PackedStringArray = [
	"_ready", "_init", "_enter_tree", "_exit_tree", "_process", "_physics_process",
	"_input", "_unhandled_input", "_unhandled_key_input", "_shortcut_input", "_gui_input",
	"_draw", "_notification", "_to_string", "_get_property_list", "_get", "_set",
	"_property_can_revert", "_property_get_revert", "_validate_property",
	"_initialize", "_finalize", "_iteration", "_run",
]

var dollar_regex := RegEx.new()
var get_node_regex := RegEx.new()
var private_func_regex := RegEx.new()


func _initialize() -> void:
	dollar_regex.compile("(^|[^\\w\"'])\\$")
	get_node_regex.compile("\\bget_node(_or_null)?\\s*\\(")
	private_func_regex.compile("^\\s*(static\\s+)?func\\s+(_\\w+)\\s*\\(")

	var violations: Array[String] = []
	for root: String in LINT_ROOTS:
		for path: String in collect_scripts(root):
			if path == SELF_PATH:
				continue
			violations.append_array(lint_file(path))

	if violations.is_empty():
		print("lint_conventions: clean (%d roots)." % LINT_ROOTS.size())
		quit(0)
		return
	for violation: String in violations:
		push_error(violation)
		print("  VIOLATION: %s" % violation)
	push_error("lint_conventions: %d violation(s)." % violations.size())
	quit(1)


func collect_scripts(p_root: String) -> PackedStringArray:
	var paths := PackedStringArray()
	var directory := DirAccess.open(p_root)
	if directory == null:
		return paths
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		var entry_path := p_root.path_join(entry)
		if directory.current_is_dir():
			paths.append_array(collect_scripts(entry_path))
		elif entry.ends_with(SCRIPT_EXTENSION):
			paths.append(entry_path)
		entry = directory.get_next()
	directory.list_dir_end()
	return paths


func lint_file(p_path: String) -> Array[String]:
	var found: Array[String] = []
	var file := FileAccess.open(p_path, FileAccess.READ)
	if file == null:
		return found
	var line_number := 0
	while not file.eof_reached():
		line_number += 1
		var line := file.get_line()
		var code := strip_comment(line)
		if dollar_regex.search(code) != null:
			found.append("%s:%d  `$` node access" % [p_path, line_number])
		if get_node_regex.search(code) != null:
			found.append("%s:%d  get_node()/get_node_or_null()" % [p_path, line_number])
		var private_match := private_func_regex.search(code)
		if private_match != null and not ALLOWED_VIRTUALS.has(private_match.get_string(2)):
			found.append("%s:%d  private method `%s()` (use a public name)" % [p_path, line_number, private_match.get_string(2)])
	return found


## Drops a trailing `#` comment (naive, but the framework has no `#` inside
## strings in code lines that also carry `$` / `get_node` / `func`).
func strip_comment(p_line: String) -> String:
	var hash_index := p_line.find("#")
	if hash_index < 0:
		return p_line
	return p_line.substr(0, hash_index)
