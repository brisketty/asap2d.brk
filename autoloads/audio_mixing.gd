class_name AudioMixingSubsystem
extends Node
## Audio Bus / Mixing. Registered as the `AudioMixing` autoload.
##
## Owns the runtime side of the bus layout: installs an SFX-bus reverb (wet 0 by
## default), and on `biome.entered` / `biome.exited` tweens the trimmable bus
## gains and the reverb toward a `BusProfile` resolved from the active
## ThemeProfile. `UI` is never touched, so interface sound stays dry. Also holds
## the central positional-audio config that SfxPlayer applies to its voices.
##
## Pure profile / target logic lives in `AudioMixingTranslation`.

const MIX_TWEEN_SECONDS := 1.5

@export_group("Spatialisation", "spatial_")
@export var spatial_max_distance: float = 2000.0
@export var spatial_attenuation: float = 1.0
@export_range(0.0, 3.0) var spatial_panning_strength: float = 1.0

var sfx_reverb: AudioEffectReverb
var active_profile_id: StringName = &"neutral"
var mix_tween: Tween


func _ready() -> void:
	install_sfx_reverb()
	EventBus.semantic_event_emitted.connect(handle_semantic_event_emitted)
	apply_bus_profile(AudioMixingTranslation.neutral_profile())


func install_sfx_reverb() -> void:
	var sfx_index := AudioServer.get_bus_index(AudioMixingTranslation.SFX_BUS)
	if sfx_index < 0:
		printerr("AudioMixing: no '%s' bus in the layout." % AudioMixingTranslation.SFX_BUS)
		return
	for i: int in AudioServer.get_bus_effect_count(sfx_index):
		var existing := AudioServer.get_bus_effect(sfx_index, i) as AudioEffectReverb
		if existing != null:
			sfx_reverb = existing
			return
	sfx_reverb = AudioEffectReverb.new()
	sfx_reverb.wet = 0.0
	AudioServer.add_bus_effect(sfx_index, sfx_reverb)


func handle_semantic_event_emitted(p_event_id: StringName, p_context: Dictionary) -> void:
	if p_event_id == EventIds.BIOME_EXITED:
		apply_bus_profile(AudioMixingTranslation.neutral_profile())
		return
	if p_event_id != EventIds.BIOME_ENTERED:
		return
	var biome_id: StringName = p_context.get(Utility.CONTEXT_SOURCE_ID_KEY, &"")
	if biome_id == &"":
		return
	var profile := ThemeManager.resolve_bus_profile(biome_id)
	if not Utility.is_object_valid(profile):
		profile = AudioMixingTranslation.neutral_profile()
	apply_bus_profile(profile)


func apply_bus_profile(p_profile: BusProfile) -> void:
	if not Utility.is_object_valid(p_profile):
		return
	active_profile_id = p_profile.profile_id
	if Utility.is_object_valid(mix_tween):
		mix_tween.kill()
	mix_tween = create_tween().set_parallel(true)

	for bus_name: StringName in AudioMixingTranslation.bus_targets(p_profile):
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			continue
		var target_db: float = AudioMixingTranslation.bus_targets(p_profile)[bus_name]
		mix_tween.tween_method(
			set_bus_volume_db.bind(bus_index), AudioServer.get_bus_volume_db(bus_index), target_db, MIX_TWEEN_SECONDS)

	if Utility.is_object_valid(sfx_reverb):
		mix_tween.tween_property(sfx_reverb, "wet",
			AudioMixingTranslation.reverb_wet_for(p_profile), MIX_TWEEN_SECONDS)
		mix_tween.tween_property(sfx_reverb, "room_size",
			AudioMixingTranslation.reverb_room_size_for(p_profile), MIX_TWEEN_SECONDS)


func set_bus_volume_db(p_db: float, p_bus_index: int) -> void:
	AudioServer.set_bus_volume_db(p_bus_index, p_db)


## Central positional-audio config, applied by SfxPlayer to each positional voice.
func apply_spatialisation(p_voice: AudioStreamPlayer2D) -> void:
	if not Utility.is_object_valid(p_voice):
		return
	p_voice.max_distance = spatial_max_distance
	p_voice.attenuation = spatial_attenuation
	p_voice.panning_strength = spatial_panning_strength


## The dry-UI guarantee, for tooling / tests: the UI bus carries no effects.
func is_ui_bus_dry() -> bool:
	var ui_index := AudioServer.get_bus_index(AudioMixingTranslation.UI_BUS)
	if ui_index < 0:
		return true
	return AudioServer.get_bus_effect_count(ui_index) == 0
