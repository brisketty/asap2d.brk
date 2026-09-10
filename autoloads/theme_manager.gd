extends Node
## Profile-Driven Translation + Defensive Defaulting. Registered as the
## `ThemeManager` autoload singleton (no `class_name` to avoid colliding with the
## autoload identifier). Every presentation asset lookup in the framework goes
## through here, so a missing asset is logged once and downgraded to a default
## instead of crashing the engine or failing silently.

signal active_profile_changed(p_profile_id: StringName)

@export_group("Profiles", "profile_")
@export var profile_available: Array[ThemeProfile] = []
## Last-resort sprite when the active ThemeProfile has no `default_sprite`.
@export var profile_fallback_sprite: Texture2D = preload("res://icon.svg")
## Last-resort stream when the active ThemeProfile has no `default_audio`.
@export var profile_fallback_audio: AudioStream
## Last-resort particle material / scene when the active ThemeProfile has no
## `default_particle`.
@export var profile_fallback_particle: Resource
## Last-resort shader material when the active ThemeProfile has no
## `default_shader`.
@export var profile_fallback_shader: ShaderMaterial

var active_profile: ThemeProfile:
	set(p_value):
		active_profile = p_value
		update_from_active_profile()


func _ready() -> void:
	if active_profile == null and not profile_available.is_empty():
		active_profile = profile_available[0]


func update_from_active_profile() -> void:
	var profile_id := &""
	if Utility.is_object_valid(active_profile):
		profile_id = active_profile.profile_id
	active_profile_changed.emit(profile_id)


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


## Never returns null: active profile -> profile default -> engine fallback.
func resolve_sprite(p_asset_id: StringName) -> Texture2D:
	if Utility.is_object_valid(active_profile):
		var found := active_profile.resolve_sprite_or_null(p_asset_id)
		if Utility.is_object_valid(found):
			return found
		var profile_default := active_profile.default_sprite
		if Utility.is_object_valid(profile_default):
			printerr("ThemeManager: sprite '%s' missing, using profile default." % p_asset_id)
			return profile_default
	printerr("ThemeManager: sprite '%s' missing, using engine fallback." % p_asset_id)
	return profile_fallback_sprite


## Never returns null (may return an empty AudioStream fallback if unconfigured).
func resolve_audio(p_asset_id: StringName) -> AudioStream:
	if Utility.is_object_valid(active_profile):
		var found := active_profile.resolve_audio_or_null(p_asset_id)
		if Utility.is_object_valid(found):
			return found
		var profile_default := active_profile.default_audio
		if Utility.is_object_valid(profile_default):
			printerr("ThemeManager: audio '%s' missing, using profile default." % p_asset_id)
			return profile_default
	printerr("ThemeManager: audio '%s' missing, using engine fallback." % p_asset_id)
	return profile_fallback_audio


## May return null: no default particle is configured out of the box (like audio).
func resolve_particle(p_asset_id: StringName) -> Resource:
	if Utility.is_object_valid(active_profile):
		var found := active_profile.resolve_particle_or_null(p_asset_id)
		if Utility.is_object_valid(found):
			return found
		var profile_default := active_profile.default_particle
		if Utility.is_object_valid(profile_default):
			printerr("ThemeManager: particle '%s' missing, using profile default." % p_asset_id)
			return profile_default
	printerr("ThemeManager: particle '%s' missing, using engine fallback." % p_asset_id)
	return profile_fallback_particle


## May return null: no default shader is configured out of the box.
func resolve_shader(p_asset_id: StringName) -> ShaderMaterial:
	if Utility.is_object_valid(active_profile):
		var found := active_profile.resolve_shader_or_null(p_asset_id)
		if Utility.is_object_valid(found):
			return found
		var profile_default := active_profile.default_shader
		if Utility.is_object_valid(profile_default):
			printerr("ThemeManager: shader '%s' missing, using profile default." % p_asset_id)
			return profile_default
	printerr("ThemeManager: shader '%s' missing, using engine fallback." % p_asset_id)
	return profile_fallback_shader


## Non-logging existence check across the active profile, for tooling.
func has_sprite(p_asset_id: StringName) -> bool:
	if not Utility.is_object_valid(active_profile):
		return false
	return Utility.is_object_valid(active_profile.resolve_sprite_or_null(p_asset_id))


func has_audio(p_asset_id: StringName) -> bool:
	if not Utility.is_object_valid(active_profile):
		return false
	return Utility.is_object_valid(active_profile.resolve_audio_or_null(p_asset_id))


func has_particle(p_asset_id: StringName) -> bool:
	if not Utility.is_object_valid(active_profile):
		return false
	return Utility.is_object_valid(active_profile.resolve_particle_or_null(p_asset_id))


func has_shader(p_asset_id: StringName) -> bool:
	if not Utility.is_object_valid(active_profile):
		return false
	return Utility.is_object_valid(active_profile.resolve_shader_or_null(p_asset_id))
