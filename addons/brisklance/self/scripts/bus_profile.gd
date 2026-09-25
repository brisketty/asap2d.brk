class_name BusProfile
extends Resource
## A named audio-mixing state: per-bus gain trims plus the SFX reverb settings.
## The AudioMixing subsystem tweens the live AudioServer toward these on a biome
## or state change. `UI` is never listed - it stays dry by construction.

@export var profile_id: StringName = &"neutral"

@export_group("Bus gain (dB, on top of the base layout)", "bus_")
@export var bus_music_db: float = 0.0
@export var bus_ambience_db: float = 0.0
@export var bus_sfx_db: float = 0.0

@export_group("SFX reverb", "reverb_")
@export_range(0.0, 1.0) var reverb_wet: float = 0.0
@export_range(0.0, 1.0) var reverb_room_size: float = 0.5
