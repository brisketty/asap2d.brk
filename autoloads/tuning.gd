extends Node
## Central Tuning. Registered as the `Tuning` autoload (no `class_name` - R3).
## Every framework subsystem constant that used to be a scattered `const` reads
## `Tuning.active_profile.<field>` instead, so swapping the active
## `TuningProfile` retunes everything at once.

signal active_profile_changed(p_profile_id: StringName)

@export_group("Profiles", "profile_")
@export var profile_available: Array[TuningProfile] = []

var active_profile: TuningProfile:
	set(p_value):
		active_profile = p_value
		update_from_active_profile()


func _ready() -> void:
	if active_profile == null:
		active_profile = profile_available[0] if not profile_available.is_empty() else TuningProfile.new()


func update_from_active_profile() -> void:
	active_profile_changed.emit(get_active_profile_id())


func get_active_profile_id() -> StringName:
	if not Utility.is_object_valid(active_profile):
		return &""
	return active_profile.profile_id


func set_active_profile_by_id(p_profile_id: StringName) -> void:
	for profile: TuningProfile in profile_available:
		if not Utility.is_object_valid(profile):
			continue
		if profile.profile_id != p_profile_id:
			continue
		active_profile = profile
		return
	printerr("Tuning: no profile registered with id '%s'." % p_profile_id)
