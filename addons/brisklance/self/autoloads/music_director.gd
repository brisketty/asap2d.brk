class_name MusicDirectorSubsystem
extends Node
## BGM & Ambience. Registered as the `MusicDirector` autoload.
##
## Runs a stack of sample-locked music stems that layer in as intensity rises
## (`music.tension`, and a floor imposed by `state.*`), crossfades between themes
## over two banks of stem players (`music.theme`), swaps a looping ambience bed
## per biome (`biome.entered`), and fires one-shot stingers (`music.stinger`).
##
## Blend / crossfade math lives in `MusicTranslation`.

const AMBIENCE_ID_PREFIX := "ambience."
const STINGER_ID_PREFIX := "stinger."

@export_group("Music", "music_")
@export var music_stem_count: int = 3
@export var music_bus: StringName = &"Music"
@export var music_ambience_bus: StringName = &"Ambience"
## `state.* -> intensity floor`. Empty uses `build_default_state_tension()`.
@export var music_state_tension: Dictionary = {}

## Flat [bank0 stem0..N, bank1 stem0..N]; index via stem().
var stem_players: Array[AudioStreamPlayer] = []
var ambience_player: AudioStreamPlayer
var stinger_player: AudioStreamPlayer

var active_bank: int = 0
var current_theme_id: StringName = &""
var current_intensity: float = 0.0
var requested_intensity: float = 0.0
var state_intensity: float = 0.0
var state_tension_lookup: Dictionary = {}
var crossfade_tween: Tween
var intensity_tween: Tween


func _ready() -> void:
	state_tension_lookup = music_state_tension
	if state_tension_lookup.is_empty():
		state_tension_lookup = MusicTranslation.build_default_state_tension()
	for i: int in music_stem_count * 2:
		var bank := i / music_stem_count
		stem_players.append(make_player(music_bus, bank == active_bank))
	ambience_player = make_player(music_ambience_bus, false)
	stinger_player = make_player(music_bus, false)
	EventBus.semantic_event_emitted.connect(handle_semantic_event_emitted)


func make_player(p_bus: StringName, p_at_target: bool) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = p_bus
	player.volume_db = 0.0 if p_at_target else Tuning.active_profile.audio_music_stem_floor_db
	add_child(player)
	return player


func stem(p_bank: int, p_index: int) -> AudioStreamPlayer:
	return stem_players[p_bank * music_stem_count + p_index]


func handle_semantic_event_emitted(p_event_id: StringName, p_context: Dictionary) -> void:
	match p_event_id:
		EventIds.MUSIC_THEME:
			play_theme(p_context.get(Utility.CONTEXT_SOURCE_ID_KEY, &""))
		EventIds.MUSIC_TENSION:
			set_intensity(float(p_context.get(Utility.CONTEXT_MAGNITUDE_KEY, 0.0)))
		EventIds.MUSIC_STINGER:
			play_stinger(p_context.get(Utility.CONTEXT_SOURCE_ID_KEY, &""))
		EventIds.BIOME_ENTERED:
			swap_ambience(p_context.get(Utility.CONTEXT_SOURCE_ID_KEY, &""))
		EventIds.BIOME_EXITED:
			swap_ambience(&"")
		EventIds.STATE_HURT, EventIds.STATE_LOWHEALTH, EventIds.STATE_PAUSED:
			set_state_intensity(MusicTranslation.state_tension(state_tension_lookup, p_event_id))
		EventIds.STATE_CLEAR:
			set_state_intensity(0.0)


func play_theme(p_theme_id: StringName) -> void:
	if p_theme_id == &"" or p_theme_id == current_theme_id:
		return
	var streams := MusicTranslation.resolve_stem_streams(ThemeManager, p_theme_id, music_stem_count)
	var incoming_bank := 1 - active_bank
	for i: int in music_stem_count:
		var player := stem(incoming_bank, i)
		var stream: AudioStream = streams[i] if i < streams.size() else null
		if not Utility.is_object_valid(stream):
			player.stop()
			continue
		player.stream = stream
		player.volume_db = Tuning.active_profile.audio_music_stem_floor_db
		player.play()
	current_theme_id = p_theme_id
	crossfade(incoming_bank)


func crossfade(p_incoming_bank: int) -> void:
	if Utility.is_object_valid(crossfade_tween):
		crossfade_tween.kill()
	var outgoing_bank := active_bank
	active_bank = p_incoming_bank
	# The incoming (now active) bank fades up to its intensity targets via
	# apply_intensity; the crossfade tween only fades the outgoing bank down, so
	# the two never animate the same player.
	apply_intensity()
	crossfade_tween = create_tween().set_parallel(true)
	for i: int in music_stem_count:
		crossfade_tween.tween_property(
			stem(outgoing_bank, i), "volume_db", Tuning.active_profile.audio_music_stem_floor_db, Tuning.active_profile.audio_music_crossfade_seconds
		)
	crossfade_tween.chain().tween_callback(stop_bank.bind(outgoing_bank))


func stop_bank(p_bank: int) -> void:
	for i: int in music_stem_count:
		stem(p_bank, i).stop()


## `music.tension` sets the requested intensity.
func set_intensity(p_value: float) -> void:
	requested_intensity = clampf(p_value, 0.0, 1.0)
	apply_intensity()


## `state.*` imposes an intensity floor; the effective level is the louder one.
func set_state_intensity(p_value: float) -> void:
	state_intensity = clampf(p_value, 0.0, 1.0)
	apply_intensity()


func apply_intensity() -> void:
	current_intensity = MusicTranslation.effective_intensity(requested_intensity, state_intensity)
	if Utility.is_object_valid(intensity_tween):
		intensity_tween.kill()
	intensity_tween = create_tween().set_parallel(true)
	for i: int in music_stem_count:
		var target := MusicTranslation.stem_volume_db(i, current_intensity, music_stem_count, Tuning.active_profile.audio_music_stem_floor_db)
		intensity_tween.tween_property(stem(active_bank, i), "volume_db", target, Tuning.active_profile.audio_music_intensity_tween_seconds)


func swap_ambience(p_biome_id: StringName) -> void:
	if p_biome_id == &"":
		ambience_player.stop()
		return
	var stream := ThemeManager.resolve_music(StringName(AMBIENCE_ID_PREFIX + p_biome_id))
	if not Utility.is_object_valid(stream):
		ambience_player.stop()
		return
	ambience_player.stream = stream
	ambience_player.play()


func play_stinger(p_stinger_id: StringName) -> void:
	if p_stinger_id == &"":
		return
	var stream := ThemeManager.resolve_music(StringName(STINGER_ID_PREFIX + p_stinger_id))
	if not Utility.is_object_valid(stream):
		return
	stinger_player.stream = stream
	stinger_player.play()
