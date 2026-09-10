class_name ThemeProfile
extends Resource
## A swappable presentation profile (biome / mood / theme). Every asset is looked
## up by an abstract StringName id; raw misses return null here so that the
## ThemeManager can apply and log the fallback centrally.

@export var profile_id: StringName

## StringName -> Texture2D.
@export var sprite_assets: Dictionary:
	set(p_value):
		sprite_assets = p_value
		update_from_sprite_assets()

## StringName -> AudioStream.
@export var audio_assets: Dictionary:
	set(p_value):
		audio_assets = p_value
		update_from_audio_assets()

## StringName -> ParticleProcessMaterial or PackedScene (kept as Resource so a
## profile can map an id to either).
@export var particle_assets: Dictionary:
	set(p_value):
		particle_assets = p_value
		update_from_particle_assets()

## StringName -> ShaderMaterial. World/environment shaders (god rays, heat haze).
@export var shader_assets: Dictionary:
	set(p_value):
		shader_assets = p_value
		update_from_shader_assets()

## StringName -> ShaderMaterial. State-driven full-screen grades (hurt vignette,
## low-health pulse) - a separate kind from `shader_assets` so tooling can tell
## "biome atmosphere" art from "damage feedback" art.
@export var post_fx_assets: Dictionary:
	set(p_value):
		post_fx_assets = p_value
		update_from_post_fx_assets()

@export var default_sprite: Texture2D
@export var default_audio: AudioStream
@export var default_particle: Resource
@export var default_shader: ShaderMaterial
@export var default_post_fx: ShaderMaterial


func update_from_sprite_assets() -> void:
	pass # Hook for derived profiles that precompute lookup state.


func update_from_audio_assets() -> void:
	pass # Hook for derived profiles that precompute lookup state.


func update_from_particle_assets() -> void:
	pass # Hook for derived profiles that precompute lookup state.


func update_from_shader_assets() -> void:
	pass # Hook for derived profiles that precompute lookup state.


func update_from_post_fx_assets() -> void:
	pass # Hook for derived profiles that precompute lookup state.


func resolve_sprite_or_null(p_asset_id: StringName) -> Texture2D:
	if not sprite_assets.has(p_asset_id):
		return null
	return sprite_assets[p_asset_id] as Texture2D


func resolve_audio_or_null(p_asset_id: StringName) -> AudioStream:
	if not audio_assets.has(p_asset_id):
		return null
	return audio_assets[p_asset_id] as AudioStream


func resolve_particle_or_null(p_asset_id: StringName) -> Resource:
	if not particle_assets.has(p_asset_id):
		return null
	return particle_assets[p_asset_id] as Resource


func resolve_shader_or_null(p_asset_id: StringName) -> ShaderMaterial:
	if not shader_assets.has(p_asset_id):
		return null
	return shader_assets[p_asset_id] as ShaderMaterial


func resolve_post_fx_or_null(p_asset_id: StringName) -> ShaderMaterial:
	if not post_fx_assets.has(p_asset_id):
		return null
	return post_fx_assets[p_asset_id] as ShaderMaterial


func collect_sprite_ids() -> PackedStringArray:
	return collect_ids_of(sprite_assets)


func collect_audio_ids() -> PackedStringArray:
	return collect_ids_of(audio_assets)


func collect_particle_ids() -> PackedStringArray:
	return collect_ids_of(particle_assets)


func collect_shader_ids() -> PackedStringArray:
	return collect_ids_of(shader_assets)


func collect_post_fx_ids() -> PackedStringArray:
	return collect_ids_of(post_fx_assets)


func collect_ids_of(p_asset_dictionary: Dictionary) -> PackedStringArray:
	var ids := PackedStringArray()
	for key: Variant in p_asset_dictionary.keys():
		ids.append(String(key))
	return ids
