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

@export var default_sprite: Texture2D
@export var default_audio: AudioStream
@export var default_particle: Resource


func update_from_sprite_assets() -> void:
	pass # Hook for derived profiles that precompute lookup state.


func update_from_audio_assets() -> void:
	pass # Hook for derived profiles that precompute lookup state.


func update_from_particle_assets() -> void:
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


func collect_sprite_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for key: Variant in sprite_assets.keys():
		ids.append(String(key))
	return ids


func collect_audio_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for key: Variant in audio_assets.keys():
		ids.append(String(key))
	return ids


func collect_particle_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for key: Variant in particle_assets.keys():
		ids.append(String(key))
	return ids
