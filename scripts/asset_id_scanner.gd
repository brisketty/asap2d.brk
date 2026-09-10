@tool
class_name AssetIdScanner
extends RefCounted
## Telemetry-Gated Scoping. Walks `.tscn` / `.tres` / `.res` files for the
## framework's scannable id exports (`*_<kind>_asset_id`, `*_event_id`) - on
## nodes, on nested custom `Resource`s, and inside exported arrays / dictionaries
## of them - and turns them into a deduped, priority-ordered worklist for artists,
## listing only ids not yet mapped in the active ThemeProfile so the list is
## zero-waste. Code-built defaults (e.g. `ImpactTranslation`'s intensity table)
## are not visible - only declared exports are.

const SPRITE_ID_SUFFIX := "_sprite_asset_id"
const AUDIO_ID_SUFFIX := "_audio_asset_id"
const PARTICLE_ID_SUFFIX := "_particle_asset_id"
const SHADER_ID_SUFFIX := "_shader_asset_id"
const POST_FX_ID_SUFFIX := "_post_fx_asset_id"
const MUSIC_ID_SUFFIX := "_music_asset_id"
const BUS_PROFILE_ID_SUFFIX := "_bus_profile_asset_id"
const EVENT_ID_SUFFIX := "_event_id"
const SCENE_EXTENSION := ".tscn"
const RESOURCE_EXTENSIONS: PackedStringArray = [".tres", ".res"]

const SPRITE_KIND := &"sprite"
const AUDIO_KIND := &"audio"
const PARTICLE_KIND := &"particle"
const SHADER_KIND := &"shader"
const POST_FX_KIND := &"post_fx"
const MUSIC_KIND := &"music"
const BUS_PROFILE_KIND := &"bus_profile"
const EVENT_KIND := &"event"


## Returns one entry per scannable export found:
## `{ scene_path, node_path, property, asset_id, kind }` (`scene_path` is the
## file the reference lives in - `.tscn` or `.tres`; `node_path` is the node
## path, or a `<res>/...` marker for a nested resource).
static func scan_directory(p_root_path: String) -> Array[Dictionary]:
	var references: Array[Dictionary] = []
	for file_path: String in collect_scannable_paths(p_root_path):
		references.append_array(scan_file(file_path))
	return references


static func collect_scannable_paths(p_root_path: String) -> PackedStringArray:
	var paths := PackedStringArray()
	var directory := DirAccess.open(p_root_path)
	if directory == null:
		printerr("AssetIdScanner: cannot open directory '%s'." % p_root_path)
		return paths
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		var entry_path := p_root_path.path_join(entry)
		if directory.current_is_dir():
			paths.append_array(collect_scannable_paths(entry_path))
		elif entry.ends_with(SCENE_EXTENSION) or has_resource_extension(entry):
			paths.append(entry_path)
		entry = directory.get_next()
	directory.list_dir_end()
	return paths


## Retained for callers/tests that only want scenes.
static func collect_scene_paths(p_root_path: String) -> PackedStringArray:
	var paths := PackedStringArray()
	for path: String in collect_scannable_paths(p_root_path):
		if path.ends_with(SCENE_EXTENSION):
			paths.append(path)
	return paths


static func has_resource_extension(p_file_name: String) -> bool:
	for extension: String in RESOURCE_EXTENSIONS:
		if p_file_name.ends_with(extension):
			return true
	return false


static func scan_file(p_path: String) -> Array[Dictionary]:
	if p_path.ends_with(SCENE_EXTENSION):
		return scan_scene(p_path)
	return scan_resource(p_path)


static func scan_scene(p_scene_path: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var packed := load(p_scene_path) as PackedScene
	if not Utility.is_object_valid(packed):
		printerr("AssetIdScanner: cannot load scene '%s'." % p_scene_path)
		return results
	# Instantiate (never entered into the tree, so `_ready` never runs) and walk
	# the live nodes: a `.tscn` SceneState only stores *overridden* export values,
	# not the scannable id declarations sitting at their script default.
	var root := packed.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
	if not Utility.is_object_valid(root):
		printerr("AssetIdScanner: cannot instantiate scene '%s'." % p_scene_path)
		return results
	var visited: Array[int] = []
	collect_ids_from_object(root, p_scene_path, ".", root, results, visited)
	root.free()
	return results


static func scan_resource(p_resource_path: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var resource := load(p_resource_path) as Resource
	# Only custom (scripted) resources carry framework id exports.
	if not Utility.is_object_valid(resource) or resource.get_script() == null:
		return results
	var visited: Array[int] = []
	collect_ids_from_object(resource, p_resource_path, "<res>", null, results, visited)
	return results


## Walks one Object's script variables: records suffixed id properties, and
## recurses into script-backed Resource values and arrays / dictionaries of them.
## `p_scene_root` is the scene root for node-path reporting (null for resources).
static func collect_ids_from_object(
	p_object: Object,
	p_source_path: String,
	p_location: String,
	p_scene_root: Node,
	r_results: Array[Dictionary],
	r_visited: Array[int],
) -> void:
	if not Utility.is_object_valid(p_object):
		return
	var object_id := p_object.get_instance_id()
	if r_visited.has(object_id):
		return
	r_visited.append(object_id)

	for property: Dictionary in p_object.get_property_list():
		if int(property[&"usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		var property_name: String = property[&"name"]
		var value: Variant = p_object.get(property_name)
		var kind := classify_property(property_name)
		if kind != &"":
			r_results.append({
				&"scene_path": p_source_path,
				&"node_path": p_location,
				&"property": property_name,
				&"asset_id": StringName(value),
				&"kind": kind,
			})
			continue
		recurse_into_value(value, p_source_path, "%s/%s" % [p_location, property_name], p_scene_root, r_results, r_visited)

	var node := p_object as Node
	if node != null:
		for child: Node in node.get_children():
			var child_location := "."
			if Utility.is_object_valid(p_scene_root):
				child_location = String(p_scene_root.get_path_to(child))
			collect_ids_from_object(child, p_source_path, child_location, p_scene_root, r_results, r_visited)


static func recurse_into_value(
	p_value: Variant,
	p_source_path: String,
	p_location: String,
	p_scene_root: Node,
	r_results: Array[Dictionary],
	r_visited: Array[int],
) -> void:
	if p_value is Resource:
		var resource := p_value as Resource
		if resource.get_script() != null:
			collect_ids_from_object(resource, p_source_path, p_location, p_scene_root, r_results, r_visited)
		return
	if p_value is Array:
		for element: Variant in p_value:
			recurse_into_value(element, p_source_path, p_location + "[]", p_scene_root, r_results, r_visited)
		return
	if p_value is Dictionary:
		for element: Variant in (p_value as Dictionary).values():
			recurse_into_value(element, p_source_path, p_location + "{}", p_scene_root, r_results, r_visited)


static func classify_property(p_property_name: String) -> StringName:
	if p_property_name.ends_with(SPRITE_ID_SUFFIX):
		return SPRITE_KIND
	if p_property_name.ends_with(BUS_PROFILE_ID_SUFFIX):
		return BUS_PROFILE_KIND
	if p_property_name.ends_with(MUSIC_ID_SUFFIX):
		return MUSIC_KIND
	if p_property_name.ends_with(AUDIO_ID_SUFFIX):
		return AUDIO_KIND
	if p_property_name.ends_with(PARTICLE_ID_SUFFIX):
		return PARTICLE_KIND
	if p_property_name.ends_with(POST_FX_ID_SUFFIX):
		return POST_FX_KIND
	if p_property_name.ends_with(SHADER_ID_SUFFIX):
		return SHADER_KIND
	if p_property_name.ends_with(EVENT_ID_SUFFIX):
		return EVENT_KIND
	return &""


## Dedupes asset references by `(kind, asset_id)`, counts how many references
## point at each, drops ids already mapped in `p_theme_manager`, and sorts by
## reference count descending (most-used art first). Event ids are excluded -
## they are not artist tasks.
static func build_task_list(p_references: Array[Dictionary], p_theme_manager) -> Array[Dictionary]:
	var tally := {}
	for reference: Dictionary in p_references:
		var kind: StringName = reference[&"kind"]
		if kind == EVENT_KIND:
			continue
		var asset_id: StringName = reference[&"asset_id"]
		if asset_id == &"":
			continue
		var key := "%s %s" % [kind, asset_id]
		if not tally.has(key):
			tally[key] = {
				&"kind": kind,
				&"asset_id": asset_id,
				&"reference_count": 0,
				&"scenes": PackedStringArray(),
			}
		var record: Dictionary = tally[key]
		record[&"reference_count"] += 1
		var scene_path: String = reference[&"scene_path"]
		if not record[&"scenes"].has(scene_path):
			record[&"scenes"].append(scene_path)

	var tasks: Array[Dictionary] = []
	for record: Dictionary in tally.values():
		if is_reference_mapped(record[&"kind"], record[&"asset_id"], p_theme_manager):
			continue
		tasks.append(record)
	tasks.sort_custom(func(p_a: Dictionary, p_b: Dictionary) -> bool:
		return p_a[&"reference_count"] > p_b[&"reference_count"])
	return tasks


static func is_reference_mapped(p_kind: StringName, p_asset_id: StringName, p_theme_manager) -> bool:
	if not Utility.is_object_valid(p_theme_manager):
		return false
	if p_kind == SPRITE_KIND:
		return p_theme_manager.has_sprite(p_asset_id)
	if p_kind == AUDIO_KIND:
		return p_theme_manager.has_audio(p_asset_id)
	if p_kind == PARTICLE_KIND:
		return p_theme_manager.has_particle(p_asset_id)
	if p_kind == SHADER_KIND:
		return p_theme_manager.has_shader(p_asset_id)
	if p_kind == POST_FX_KIND:
		return p_theme_manager.has_post_fx(p_asset_id)
	if p_kind == MUSIC_KIND:
		return p_theme_manager.has_music(p_asset_id)
	if p_kind == BUS_PROFILE_KIND:
		return p_theme_manager.has_bus_profile(p_asset_id)
	return false


static func format_task_list(p_tasks: Array[Dictionary]) -> String:
	if p_tasks.is_empty():
		return "AssetIdScanner: no unmapped assets - worklist is empty."
	var lines := PackedStringArray()
	lines.append("AssetIdScanner: %d unmapped asset(s), most-referenced first:" % p_tasks.size())
	for task: Dictionary in p_tasks:
		lines.append("  [%s] %s  (x%d)  %s" % [
			task[&"kind"],
			task[&"asset_id"],
			task[&"reference_count"],
			", ".join(task[&"scenes"]),
		])
	return "\n".join(lines)
