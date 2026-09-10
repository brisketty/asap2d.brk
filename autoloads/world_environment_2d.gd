class_name WorldEnvironment2DSubsystem
extends Node
## World & Environment. Registered as the `WorldEnvironment2D` autoload.
##
## On `biome.entered` it switches the active ThemeProfile to the biome id (so
## every other subsystem re-themes too) and rebuilds its own persistent parallax
## rig, ambient particle layer and full-screen shader overlay by resolving a
## fixed set of abstract ids through the (now biome-specific) profile. On
## `biome.exited` it tears those down.
##
## Pure distribution / resolution logic lives in `WorldTranslation`.

## Abstract ids the subsystem resolves every rebuild. A ThemeProfile maps these
## per biome. Far -> near.
const PARALLAX_LAYER_IDS: PackedStringArray = [
	"world.parallax.far", "world.parallax.mid", "world.parallax.near",
]
const AMBIENT_PARTICLE_ID := &"world.ambient"
const OVERLAY_SHADER_ID := &"world.overlay"

const SCROLL_SCALE_MIN := 0.15
const SCROLL_SCALE_MAX := 1.0

var parallax_rig: ParallaxRig
var ambient_layer: AmbientParticleLayer
var shader_overlay: ScreenShaderOverlay

var active_biome_id: StringName = &""
var is_rebuilding: bool = false


func _ready() -> void:
	parallax_rig = ParallaxRig.get_packed_scene().instantiate()
	add_child(parallax_rig)
	ambient_layer = AmbientParticleLayer.get_packed_scene().instantiate()
	add_child(ambient_layer)
	shader_overlay = ScreenShaderOverlay.get_packed_scene().instantiate()
	add_child(shader_overlay)
	EventBus.semantic_event_emitted.connect(handle_semantic_event_emitted)
	ThemeManager.active_profile_changed.connect(handle_active_profile_changed)


func handle_semantic_event_emitted(p_event_id: StringName, p_context: Dictionary) -> void:
	if p_event_id == EventIds.BIOME_EXITED:
		clear_world()
		return
	if p_event_id != EventIds.BIOME_ENTERED:
		return
	var biome_id: StringName = p_context.get(Utility.CONTEXT_SOURCE_ID_KEY, &"")
	if biome_id == &"":
		return
	active_biome_id = biome_id
	if WorldTranslation.should_switch_profile(ThemeManager.get_active_profile_id(), biome_id):
		ThemeManager.set_active_profile_by_id(biome_id)
	rebuild_world()


func handle_active_profile_changed(_p_profile_id: StringName) -> void:
	# Re-theme if another subsystem swapped the profile while a biome is active.
	if active_biome_id != &"":
		rebuild_world()


func rebuild_world() -> void:
	if is_rebuilding:
		return
	is_rebuilding = true
	var textures := WorldTranslation.resolve_layer_textures(ThemeManager, PARALLAX_LAYER_IDS)
	var scroll_scales := WorldTranslation.build_scroll_scales(textures.size(), SCROLL_SCALE_MIN, SCROLL_SCALE_MAX)
	parallax_rig.configure(textures, scroll_scales)
	ambient_layer.configure(ThemeManager.resolve_particle(AMBIENT_PARTICLE_ID))
	shader_overlay.configure(ThemeManager.resolve_shader(OVERLAY_SHADER_ID))
	is_rebuilding = false


func clear_world() -> void:
	active_biome_id = &""
	parallax_rig.configure([] as Array[Texture2D], PackedFloat32Array())
	ambient_layer.configure(null)
	shader_overlay.configure(null)
