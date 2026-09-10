class_name AudioMixingTranslation
## Pure logic for the Audio Bus / Mixing subsystem: neutral / built profiles,
## the bus -> target-dB map, reverb clamping, and the dry-bus rule. No
## AudioServer calls, unit-tested headless.

const MUSIC_BUS := &"Music"
const AMBIENCE_BUS := &"Ambience"
const SFX_BUS := &"SFX"
const UI_BUS := &"UI"


## The default "no colour" state: flat gains, no reverb.
static func neutral_profile() -> BusProfile:
	var profile := BusProfile.new()
	profile.profile_id = &"neutral"
	return profile


static func make_profile(
	p_id: StringName,
	p_music_db: float,
	p_ambience_db: float,
	p_sfx_db: float,
	p_reverb_wet: float,
	p_reverb_room_size: float,
) -> BusProfile:
	var profile := BusProfile.new()
	profile.profile_id = p_id
	profile.bus_music_db = p_music_db
	profile.bus_ambience_db = p_ambience_db
	profile.bus_sfx_db = p_sfx_db
	profile.reverb_wet = p_reverb_wet
	profile.reverb_room_size = p_reverb_room_size
	return profile


## `bus name -> target dB` for the trimmable buses. `UI` is never included -
## it stays at its base level so interface sound is always dry and predictable.
static func bus_targets(p_profile: BusProfile) -> Dictionary:
	if not Utility.is_object_valid(p_profile):
		return {}
	return {
		MUSIC_BUS: p_profile.bus_music_db,
		AMBIENCE_BUS: p_profile.bus_ambience_db,
		SFX_BUS: p_profile.bus_sfx_db,
	}


## True for buses that must never receive reverb / gain colour.
static func is_dry_bus(p_bus_name: StringName) -> bool:
	return p_bus_name == UI_BUS


static func reverb_wet_for(p_profile: BusProfile) -> float:
	if not Utility.is_object_valid(p_profile):
		return 0.0
	return clampf(p_profile.reverb_wet, 0.0, 1.0)


static func reverb_room_size_for(p_profile: BusProfile) -> float:
	if not Utility.is_object_valid(p_profile):
		return 0.5
	return clampf(p_profile.reverb_room_size, 0.0, 1.0)
