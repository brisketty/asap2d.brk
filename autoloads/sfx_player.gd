class_name SfxPlayerSubsystem
extends Node
## Polyphonic Audio (SFX). Registered as the `SfxPlayer` autoload.
##
## Maps semantic events to pooled one-shot sounds through a route table: a
## positional `AudioStreamPlayer2D` pool for world SFX, a dry `AudioStreamPlayer`
## pool for UI. Pitch and gain are randomised per route. The pools live under
## this autoload, so voices are never freed by a scene change - call
## `notify_scene_change()` to cut the transient ones.
##
## Pure route lookup / randomisation lives in `SfxTranslation`.

const POSITIONAL_VOICE_SCENE := "res://prefabs/sfx_voice_2d.tscn"
const UI_VOICE_SCENE := "res://prefabs/sfx_voice_ui.tscn"

@export_group("Routes", "route_")
## Leave empty to use `SfxTranslation.build_default_route_table()`.
@export var route_table: Array[SfxRoute] = []

var positional_pool: SfxVoicePool
var ui_pool: SfxVoicePool
var routes_by_event_id: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	rebuild_route_lookup()
	positional_pool = build_pool(POSITIONAL_VOICE_SCENE)
	ui_pool = build_pool(UI_VOICE_SCENE)
	EventBus.semantic_event_emitted.connect(handle_semantic_event_emitted)


func build_pool(p_voice_scene_path: String) -> SfxVoicePool:
	var pool := SfxVoicePool.get_packed_scene().instantiate()
	pool.pool_voice_scene = load(p_voice_scene_path)
	add_child(pool)
	return pool


func rebuild_route_lookup() -> void:
	var table := route_table
	if table.is_empty():
		table = SfxTranslation.build_default_route_table()
	routes_by_event_id = SfxTranslation.build_lookup(table)


func resolve_route(p_event_id: StringName) -> SfxRoute:
	return routes_by_event_id.get(p_event_id)


func handle_semantic_event_emitted(p_event_id: StringName, p_context: Dictionary) -> void:
	var route := resolve_route(p_event_id)
	if not Utility.is_object_valid(route):
		return
	var stream := ThemeManager.resolve_audio(route.route_audio_asset_id)
	var pitch := SfxTranslation.random_pitch_scale(route.route_pitch_semitones, rng.randf_range(-1.0, 1.0))
	var volume_db := SfxTranslation.random_volume_db(route.route_volume_db_range, rng.randf_range(-1.0, 1.0))
	var keep := SfxTranslation.should_keep_on_scene_change(route)
	if route.route_spatialized:
		var position: Vector2 = p_context.get(Utility.CONTEXT_POSITION_KEY, Vector2.ZERO)
		positional_pool.play(stream, pitch, volume_db, position, keep)
		return
	ui_pool.play(stream, pitch, volume_db, Vector2.ZERO, keep)


## Call before swapping scenes: transient voices (routes with
## `route_stop_on_scene_change`) are cut; the rest play out.
func notify_scene_change() -> void:
	if Utility.is_object_valid(positional_pool):
		positional_pool.stop_transient()
	if Utility.is_object_valid(ui_pool):
		ui_pool.stop_transient()
