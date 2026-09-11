extends Node
## Profile-Driven Translation + Defensive Defaulting. Registered as the
## `ThemeManager` autoload singleton (no `class_name` to avoid colliding with the
## autoload identifier). Every presentation asset lookup in the framework goes
## through here, so a missing asset is logged once and downgraded to a default
## instead of crashing the engine or failing silently.
##
## Each asset kind keeps an explicit typed dictionary on `ThemeProfile` (so it
## reads well in the inspector) and a two-line `resolve_<kind>` / `has_<kind>`
## pair here, both built on `resolve_with_ladder` / `profile_asset_or_null`.

signal active_profile_changed(p_profile_id: StringName)

@export_group("Profiles", "profile_")
@export var profile_available: Array[ThemeProfile] = []
## Last-resort assets, used when the active ThemeProfile has no `default_<kind>`.
@export var profile_fallback_sprite: Texture2D = preload("res://icon.svg")
@export var profile_fallback_audio: AudioStream
@export var profile_fallback_particle: Resource
@export var profile_fallback_shader: ShaderMaterial
@export var profile_fallback_post_fx: ShaderMaterial
@export var profile_fallback_music: AudioStream
@export var profile_fallback_bus_profile: BusProfile
@export var profile_fallback_tileset: TileSet
## Left unset by default - a missing screen-tile border means "show nothing",
## the correct defensive default (unlike sprite/tileset, there is no engine
## placeholder that would make sense here).
@export var profile_fallback_screen_tile: ScreenTileSet

var active_profile: ThemeProfile:
	set(p_value):
		active_profile = p_value
		update_from_active_profile()


func _ready() -> void:
	if active_profile == null and not profile_available.is_empty():
		active_profile = profile_available[0]


func update_from_active_profile() -> void:
	active_profile_changed.emit(get_active_profile_id())


func get_active_profile_id() -> StringName:
	if not Utility.is_object_valid(active_profile):
		return &""
	return active_profile.profile_id


func set_active_profile_by_id(p_profile_id: StringName) -> void:
	for profile: ThemeProfile in profile_available:
		if not Utility.is_object_valid(profile):
			continue
		if profile.profile_id != p_profile_id:
			continue
		active_profile = profile
		return
	printerr("ThemeManager: no profile registered with id '%s'." % p_profile_id)


# --- generic resolution ladder ---

## Raw active-profile lookup (`p_method` is a `ThemeProfile.resolve_*_or_null`),
## or null when there is no valid profile.
func profile_asset_or_null(p_method: StringName, p_asset_id: StringName) -> Variant:
	if not Utility.is_object_valid(active_profile):
		return null
	return active_profile.call(p_method, p_asset_id)


func profile_default_or_null(p_property: StringName) -> Variant:
	if not Utility.is_object_valid(active_profile):
		return null
	return active_profile.get(p_property)


## The defensive-default ladder every `resolve_<kind>` shares:
## a valid profile asset -> a valid profile default -> the engine fallback.
## Logs once on each downgrade.
func resolve_with_ladder(
	p_kind: String,
	p_asset_id: StringName,
	p_profile_asset: Variant,
	p_profile_default: Variant,
	p_engine_fallback: Variant,
) -> Variant:
	if Utility.is_object_valid(p_profile_asset):
		return p_profile_asset
	if Utility.is_object_valid(active_profile) and Utility.is_object_valid(p_profile_default):
		printerr("ThemeManager: %s '%s' missing, using profile default." % [p_kind, p_asset_id])
		return p_profile_default
	printerr("ThemeManager: %s '%s' missing, using engine fallback." % [p_kind, p_asset_id])
	return p_engine_fallback


# --- typed resolve_<kind> / has_<kind> (sprite never null; the rest may be null
#     until the project configures the matching profile_fallback_*) ---

func resolve_sprite(p_asset_id: StringName) -> Texture2D:
	return resolve_with_ladder("sprite", p_asset_id,
		profile_asset_or_null(&"resolve_sprite_or_null", p_asset_id),
		profile_default_or_null(&"default_sprite"), profile_fallback_sprite) as Texture2D


func resolve_audio(p_asset_id: StringName) -> AudioStream:
	return resolve_with_ladder("audio", p_asset_id,
		profile_asset_or_null(&"resolve_audio_or_null", p_asset_id),
		profile_default_or_null(&"default_audio"), profile_fallback_audio) as AudioStream


func resolve_particle(p_asset_id: StringName) -> Resource:
	return resolve_with_ladder("particle", p_asset_id,
		profile_asset_or_null(&"resolve_particle_or_null", p_asset_id),
		profile_default_or_null(&"default_particle"), profile_fallback_particle) as Resource


func resolve_shader(p_asset_id: StringName) -> ShaderMaterial:
	return resolve_with_ladder("shader", p_asset_id,
		profile_asset_or_null(&"resolve_shader_or_null", p_asset_id),
		profile_default_or_null(&"default_shader"), profile_fallback_shader) as ShaderMaterial


func resolve_post_fx(p_asset_id: StringName) -> ShaderMaterial:
	return resolve_with_ladder("post-fx", p_asset_id,
		profile_asset_or_null(&"resolve_post_fx_or_null", p_asset_id),
		profile_default_or_null(&"default_post_fx"), profile_fallback_post_fx) as ShaderMaterial


func resolve_music(p_asset_id: StringName) -> AudioStream:
	return resolve_with_ladder("music", p_asset_id,
		profile_asset_or_null(&"resolve_music_or_null", p_asset_id),
		profile_default_or_null(&"default_music"), profile_fallback_music) as AudioStream


func resolve_bus_profile(p_asset_id: StringName) -> BusProfile:
	return resolve_with_ladder("bus-profile", p_asset_id,
		profile_asset_or_null(&"resolve_bus_profile_or_null", p_asset_id),
		profile_default_or_null(&"default_bus_profile"), profile_fallback_bus_profile) as BusProfile


func resolve_tileset(p_asset_id: StringName) -> TileSet:
	return resolve_with_ladder("tileset", p_asset_id,
		profile_asset_or_null(&"resolve_tileset_or_null", p_asset_id),
		profile_default_or_null(&"default_tileset"), profile_fallback_tileset) as TileSet


func resolve_screen_tile(p_asset_id: StringName) -> ScreenTileSet:
	return resolve_with_ladder("screen-tile", p_asset_id,
		profile_asset_or_null(&"resolve_screen_tile_or_null", p_asset_id),
		profile_default_or_null(&"default_screen_tile"), profile_fallback_screen_tile) as ScreenTileSet


func has_sprite(p_asset_id: StringName) -> bool:
	return Utility.is_object_valid(profile_asset_or_null(&"resolve_sprite_or_null", p_asset_id))


func has_audio(p_asset_id: StringName) -> bool:
	return Utility.is_object_valid(profile_asset_or_null(&"resolve_audio_or_null", p_asset_id))


func has_particle(p_asset_id: StringName) -> bool:
	return Utility.is_object_valid(profile_asset_or_null(&"resolve_particle_or_null", p_asset_id))


func has_shader(p_asset_id: StringName) -> bool:
	return Utility.is_object_valid(profile_asset_or_null(&"resolve_shader_or_null", p_asset_id))


func has_post_fx(p_asset_id: StringName) -> bool:
	return Utility.is_object_valid(profile_asset_or_null(&"resolve_post_fx_or_null", p_asset_id))


func has_music(p_asset_id: StringName) -> bool:
	return Utility.is_object_valid(profile_asset_or_null(&"resolve_music_or_null", p_asset_id))


func has_bus_profile(p_asset_id: StringName) -> bool:
	return Utility.is_object_valid(profile_asset_or_null(&"resolve_bus_profile_or_null", p_asset_id))


func has_tileset(p_asset_id: StringName) -> bool:
	return Utility.is_object_valid(profile_asset_or_null(&"resolve_tileset_or_null", p_asset_id))


func has_screen_tile(p_asset_id: StringName) -> bool:
	return Utility.is_object_valid(profile_asset_or_null(&"resolve_screen_tile_or_null", p_asset_id))
