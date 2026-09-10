extends SceneTree

## Stub with the same surface AssetIdScanner.build_task_list needs from a
## ThemeManager: it treats a fixed set of ids as already mapped.
class StubThemeManager:
	extends RefCounted
	var mapped_sprites: PackedStringArray = []
	var mapped_audio: PackedStringArray = []
	var mapped_particles: PackedStringArray = []
	var mapped_shaders: PackedStringArray = []
	var mapped_post_fx: PackedStringArray = []
	var mapped_music: PackedStringArray = []
	var mapped_bus_profiles: PackedStringArray = []
	var mapped_tilesets: PackedStringArray = []

	func has_sprite(p_asset_id: StringName) -> bool:
		return mapped_sprites.has(String(p_asset_id))

	func has_audio(p_asset_id: StringName) -> bool:
		return mapped_audio.has(String(p_asset_id))

	func has_particle(p_asset_id: StringName) -> bool:
		return mapped_particles.has(String(p_asset_id))

	func has_shader(p_asset_id: StringName) -> bool:
		return mapped_shaders.has(String(p_asset_id))

	func has_post_fx(p_asset_id: StringName) -> bool:
		return mapped_post_fx.has(String(p_asset_id))

	func has_music(p_asset_id: StringName) -> bool:
		return mapped_music.has(String(p_asset_id))

	func has_bus_profile(p_asset_id: StringName) -> bool:
		return mapped_bus_profiles.has(String(p_asset_id))

	func has_tileset(p_asset_id: StringName) -> bool:
		return mapped_tilesets.has(String(p_asset_id))


func _initialize() -> void:
	var failure_count := 0

	failure_count += expect_true("sprite suffix classified", AssetIdScanner.classify_property("node_x_sprite_asset_id") == AssetIdScanner.SPRITE_KIND)
	failure_count += expect_true("audio suffix classified", AssetIdScanner.classify_property("boom_audio_asset_id") == AssetIdScanner.AUDIO_KIND)
	failure_count += expect_true("particle suffix classified", AssetIdScanner.classify_property("burst_particle_asset_id") == AssetIdScanner.PARTICLE_KIND)
	failure_count += expect_true("shader suffix classified", AssetIdScanner.classify_property("haze_shader_asset_id") == AssetIdScanner.SHADER_KIND)
	failure_count += expect_true("post_fx suffix classified", AssetIdScanner.classify_property("hurt_post_fx_asset_id") == AssetIdScanner.POST_FX_KIND)
	failure_count += expect_true("music suffix classified", AssetIdScanner.classify_property("theme_music_asset_id") == AssetIdScanner.MUSIC_KIND)
	failure_count += expect_true("bus_profile suffix classified", AssetIdScanner.classify_property("cave_bus_profile_asset_id") == AssetIdScanner.BUS_PROFILE_KIND)
	failure_count += expect_true("tileset suffix classified", AssetIdScanner.classify_property("ground_tileset_asset_id") == AssetIdScanner.TILESET_KIND)
	failure_count += expect_true("event suffix classified", AssetIdScanner.classify_property("hit_event_id") == AssetIdScanner.EVENT_KIND)
	failure_count += expect_true("unrelated property ignored", AssetIdScanner.classify_property("position") == &"")

	var references: Array[Dictionary] = [
		{&"scene_path": "res://a.tscn", &"node_path": ".", &"property": "p", &"asset_id": &"impact.spark", &"kind": AssetIdScanner.SPRITE_KIND},
		{&"scene_path": "res://b.tscn", &"node_path": ".", &"property": "p", &"asset_id": &"impact.spark", &"kind": AssetIdScanner.SPRITE_KIND},
		{&"scene_path": "res://b.tscn", &"node_path": ".", &"property": "p", &"asset_id": &"impact.dust", &"kind": AssetIdScanner.SPRITE_KIND},
		{&"scene_path": "res://b.tscn", &"node_path": ".", &"property": "p", &"asset_id": &"impact.basic", &"kind": AssetIdScanner.EVENT_KIND},
		{&"scene_path": "res://b.tscn", &"node_path": ".", &"property": "p", &"asset_id": &"boom", &"kind": AssetIdScanner.AUDIO_KIND},
	]

	var stub := StubThemeManager.new()
	stub.mapped_sprites = ["boom"] # irrelevant kind; boom is audio and unmapped

	var tasks := AssetIdScanner.build_task_list(references, stub)
	failure_count += expect_int("event id excluded, 3 asset tasks", tasks.size(), 3)
	failure_count += expect_true("most-referenced first", tasks[0][&"asset_id"] == &"impact.spark")
	failure_count += expect_int("dedup keeps a single spark task at count 2", tasks[0][&"reference_count"], 2)
	failure_count += expect_int("spark seen in two scenes", (tasks[0][&"scenes"] as PackedStringArray).size(), 2)

	stub.mapped_sprites = ["impact.spark"]
	var trimmed := AssetIdScanner.build_task_list(references, stub)
	failure_count += expect_true("mapped sprite dropped from worklist", not has_asset(trimmed, &"impact.spark"))
	failure_count += expect_int("worklist now 2 (dust + boom)", trimmed.size(), 2)

	var scene_paths := AssetIdScanner.collect_scene_paths("res://scenes")
	failure_count += expect_true("demo scene discovered", scene_paths.has("res://scenes/foundation_demo.tscn"))

	# --- scans scripted .tres for nested suffixed ids ---
	var scannable := AssetIdScanner.collect_scannable_paths("res://tests")
	failure_count += expect_true("resource files are scannable", scannable.has("res://tests/fixture_intensity.tres"))

	var from_resource := AssetIdScanner.scan_resource("res://tests/fixture_intensity.tres")
	failure_count += expect_true("scans a scripted .tres", has_asset(from_resource, &"fixture.spark"))
	failure_count += expect_true("classifies the nested particle id",
		kind_of(from_resource, &"fixture.spark") == AssetIdScanner.PARTICLE_KIND)
	failure_count += expect_true("also picks up the nested event id",
		kind_of(from_resource, &"impact.basic") == AssetIdScanner.EVENT_KIND)
	failure_count += expect_true("engine .tres (no script) yields nothing",
		AssetIdScanner.scan_resource("res://assets/shader_forest_tint.tres").is_empty())

	if failure_count > 0:
		push_error("%d asset-id-scanner test(s) failed." % failure_count)
		quit(1)
		return
	print("All asset-id-scanner tests passed.")
	quit(0)


func has_asset(p_tasks: Array[Dictionary], p_asset_id: StringName) -> bool:
	for task: Dictionary in p_tasks:
		if task[&"asset_id"] == p_asset_id:
			return true
	return false


func kind_of(p_references: Array[Dictionary], p_asset_id: StringName) -> StringName:
	for reference: Dictionary in p_references:
		if reference[&"asset_id"] == p_asset_id:
			return reference[&"kind"]
	return &""


func expect_int(p_label: String, p_actual: int, p_expected: int) -> int:
	if p_actual == p_expected:
		print("  ok: %s" % p_label)
		return 0
	push_error("  FAIL: %s (expected %d, got %d)" % [p_label, p_expected, p_actual])
	return 1


func expect_true(p_label: String, p_actual: bool) -> int:
	if p_actual:
		print("  ok: %s" % p_label)
		return 0
	push_error("  FAIL: %s" % p_label)
	return 1
