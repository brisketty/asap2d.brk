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

const POSITIONAL_VOICE_SCENE := "res://addons/brisklance/self/prefabs/sfx_voice_2d.tscn"
const UI_VOICE_SCENE := "res://addons/brisklance/self/prefabs/sfx_voice_ui.tscn"

const STATE_LOOP_BUS := &"SFX"

@export_group("Routes", "route_")
## Leave empty to use `SfxTranslation.build_default_route_table()`.
@export var route_table: Array[SfxRoute] = []

@export_group("States", "state_")
## Enter/loop/exit sounds for `state.*` events. Leave empty to use
## `SfxTranslation.build_default_state_sfx_table()`.
@export var state_sfx_table: Array[StateSfxSet] = []

var positional_pool: SfxVoicePool
var ui_pool: SfxVoicePool
var routes_by_event_id: Dictionary = {}
var state_sfx_by_event_id: Dictionary = {}
var state_loop_player: AudioStreamPlayer
var active_state_id: StringName = &""
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	rebuild_route_lookup()
	rebuild_state_sfx_lookup()
	positional_pool = build_pool(POSITIONAL_VOICE_SCENE)
	ui_pool = build_pool(UI_VOICE_SCENE)
	state_loop_player = AudioStreamPlayer.new()
	state_loop_player.bus = STATE_LOOP_BUS
	add_child(state_loop_player)
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


func rebuild_state_sfx_lookup() -> void:
	var table := state_sfx_table
	if table.is_empty():
		table = SfxTranslation.build_default_state_sfx_table()
	state_sfx_by_event_id = SfxTranslation.build_state_sfx_lookup(table)


func resolve_route(p_event_id: StringName) -> SfxRoute:
	return routes_by_event_id.get(p_event_id)


func handle_semantic_event_emitted(p_event_id: StringName, p_context: Dictionary) -> void:
	var route := resolve_route(p_event_id)
	if Utility.is_object_valid(route):
		play_route(route, p_context)

	match p_event_id:
		EventIds.STATE_HURT, EventIds.STATE_LOWHEALTH, EventIds.STATE_PAUSED:
			handle_state_entered(p_event_id)
		EventIds.STATE_CLEAR:
			handle_state_cleared()


func play_route(p_route: SfxRoute, p_context: Dictionary) -> void:
	var audio_asset_id := SfxTranslation.pick_variation_id(
		p_route.route_audio_variation_ids, p_route.route_audio_asset_id, rng.randf()
	)
	var stream := ThemeManager.resolve_audio(audio_asset_id)
	var pitch := SfxTranslation.random_pitch_scale(p_route.route_pitch_semitones, rng.randf_range(-1.0, 1.0))
	var volume_db := SfxTranslation.random_volume_db(p_route.route_volume_db_range, rng.randf_range(-1.0, 1.0))
	var keep := SfxTranslation.should_keep_on_scene_change(p_route)
	if p_route.route_spatialized:
		var position: Vector2 = p_context.get(Utility.CONTEXT_POSITION_KEY, Vector2.ZERO)
		var voice := positional_pool.play(stream, pitch, volume_db, position, keep) as AudioStreamPlayer2D
		if Utility.is_object_valid(voice):
			AudioMixing.apply_spatialisation(voice)
		return
	ui_pool.play(stream, pitch, volume_db, Vector2.ZERO, keep)


func handle_state_entered(p_event_id: StringName) -> void:
	stop_state_loop()
	active_state_id = p_event_id
	var state_sfx: StateSfxSet = SfxTranslation.resolve_state_sfx(state_sfx_by_event_id, p_event_id)
	if not Utility.is_object_valid(state_sfx):
		return
	play_one_shot_variation(state_sfx.enter_audio_variation_ids, state_sfx.enter_pitch_semitones)
	start_state_loop(state_sfx.loop_audio_variation_ids, state_sfx.loop_pitch_semitones)


func handle_state_cleared() -> void:
	stop_state_loop()
	var state_sfx: StateSfxSet = SfxTranslation.resolve_state_sfx(state_sfx_by_event_id, active_state_id)
	active_state_id = &""
	if not Utility.is_object_valid(state_sfx):
		return
	play_one_shot_variation(state_sfx.exit_audio_variation_ids, state_sfx.exit_pitch_semitones)


func play_one_shot_variation(p_variation_ids: Array[StringName], p_pitch_semitones: float) -> void:
	if p_variation_ids.is_empty():
		return
	var audio_asset_id := SfxTranslation.pick_variation_id(p_variation_ids, &"", rng.randf())
	var stream := ThemeManager.resolve_audio(audio_asset_id)
	var pitch := SfxTranslation.random_pitch_scale(p_pitch_semitones, rng.randf_range(-1.0, 1.0))
	ui_pool.play(stream, pitch, 0.0, Vector2.ZERO, false)


func start_state_loop(p_variation_ids: Array[StringName], p_pitch_semitones: float) -> void:
	if p_variation_ids.is_empty() or not Utility.is_object_valid(state_loop_player):
		return
	var audio_asset_id := SfxTranslation.pick_variation_id(p_variation_ids, &"", rng.randf())
	var stream := ThemeManager.resolve_audio(audio_asset_id)
	if not Utility.is_object_valid(stream):
		return
	state_loop_player.stream = stream
	state_loop_player.pitch_scale = SfxTranslation.random_pitch_scale(p_pitch_semitones, rng.randf_range(-1.0, 1.0))
	state_loop_player.play()


func stop_state_loop() -> void:
	if Utility.is_object_valid(state_loop_player):
		state_loop_player.stop()


## Call before swapping scenes: transient voices (routes with
## `route_stop_on_scene_change`) are cut; the rest play out.
func notify_scene_change() -> void:
	if Utility.is_object_valid(positional_pool):
		positional_pool.stop_transient()
	if Utility.is_object_valid(ui_pool):
		ui_pool.stop_transient()
