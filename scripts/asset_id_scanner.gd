@tool
class_name AssetIdScanner
extends RefCounted
## Telemetry-Gated Scoping. Statically parses `.tscn` files for the framework's
## scannable id exports (`*_sprite_asset_id`, `*_audio_asset_id`, `*_event_id`)
## and turns them into a deduped, priority-ordered worklist for artists -
## listing only ids that are not yet mapped in the active ThemeProfile so the
## list is zero-waste.

const SPRITE_ID_SUFFIX := "_sprite_asset_id"
const AUDIO_ID_SUFFIX := "_audio_asset_id"
const PARTICLE_ID_SUFFIX := "_particle_asset_id"
const EVENT_ID_SUFFIX := "_event_id"
const SCENE_EXTENSION := ".tscn"

const SPRITE_KIND := &"sprite"
const AUDIO_KIND := &"audio"
const PARTICLE_KIND := &"particle"
const EVENT_KIND := &"event"


## Returns one entry per scannable export found:
## `{ scene_path, node_path, property, asset_id, kind }`.
static func scan_directory(p_root_path: String) -> Array[Dictionary]:
	var references: Array[Dictionary] = []
	for scene_path: String in collect_scene_paths(p_root_path):
		references.append_array(scan_scene(scene_path))
	return references


static func collect_scene_paths(p_root_path: String) -> PackedStringArray:
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
			paths.append_array(collect_scene_paths(entry_path))
		elif entry.ends_with(SCENE_EXTENSION):
			paths.append(entry_path)
		entry = directory.get_next()
	directory.list_dir_end()
	return paths


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
	collect_ids_from_node(root, root, p_scene_path, results)
	root.free()
	return results


static func collect_ids_from_node(
	p_node: Node,
	p_root: Node,
	p_scene_path: String,
	r_results: Array[Dictionary],
) -> void:
	for property: Dictionary in p_node.get_property_list():
		var property_name: String = property[&"name"]
		var kind := classify_property(property_name)
		if kind == &"":
			continue
		r_results.append({
			&"scene_path": p_scene_path,
			&"node_path": String(p_root.get_path_to(p_node)),
			&"property": property_name,
			&"asset_id": StringName(p_node.get(property_name)),
			&"kind": kind,
		})
	for child: Node in p_node.get_children():
		collect_ids_from_node(child, p_root, p_scene_path, r_results)


static func classify_property(p_property_name: String) -> StringName:
	if p_property_name.ends_with(SPRITE_ID_SUFFIX):
		return SPRITE_KIND
	if p_property_name.ends_with(AUDIO_ID_SUFFIX):
		return AUDIO_KIND
	if p_property_name.ends_with(PARTICLE_ID_SUFFIX):
		return PARTICLE_KIND
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
