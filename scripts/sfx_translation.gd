class_name SfxTranslation
## Pure logic for the Polyphonic Audio subsystem: route-table lookup and
## pitch / volume randomisation. No engine state, unit-tested headless.

const SEMITONE_RATIO_BASE := 2.0
const SEMITONES_PER_OCTAVE := 12.0


static func build_lookup(p_table: Array[SfxRoute]) -> Dictionary:
	var lookup: Dictionary = {}
	for route: SfxRoute in p_table:
		if not Utility.is_object_valid(route):
			continue
		lookup[route.route_event_id] = route
	return lookup


static func build_default_route_table() -> Array[SfxRoute]:
	return [
		make_route(EventIds.IMPACT_BASIC, &"sfx.impact.light", true, 2.0, 3.0),
		make_route(EventIds.IMPACT_HEAVY, &"sfx.impact.heavy", true, 1.5, 2.0),
		make_route(EventIds.IMPACT_CRIT, &"sfx.impact.crit", true, 1.0, 2.0),
		make_route(EventIds.UI_HOVER, &"sfx.ui.hover", false, 0.5, 1.5),
		make_route(EventIds.UI_CONFIRM, &"sfx.ui.confirm", false, 0.0, 1.0),
		make_route(EventIds.UI_CANCEL, &"sfx.ui.cancel", false, 0.0, 1.0),
		# camera.* - momentary effects, same treatment as an impact (no
		# enter/during/exit lifecycle; see StateSfxSet for that).
		make_route(EventIds.CAMERA_SHAKE, &"sfx.camera.shake", false, 1.5, 2.0),
		make_route(EventIds.CAMERA_ZOOM, &"sfx.camera.zoom", false, 1.0, 1.5),
	]


static func make_route(
	p_event_id: StringName,
	p_audio_asset_id: StringName,
	p_spatialized: bool,
	p_pitch_semitones: float,
	p_volume_db_range: float,
	p_variation_ids: Array[StringName] = [],
) -> SfxRoute:
	var route := SfxRoute.new()
	route.route_event_id = p_event_id
	route.route_audio_asset_id = p_audio_asset_id
	route.route_spatialized = p_spatialized
	route.route_pitch_semitones = p_pitch_semitones
	route.route_volume_db_range = p_volume_db_range
	route.route_audio_variation_ids = p_variation_ids
	return route


static func resolve_route(p_lookup: Dictionary, p_event_id: StringName) -> SfxRoute:
	return p_lookup.get(p_event_id)


# --- state enter/loop/exit sfx table ---

static func build_state_sfx_lookup(p_table: Array[StateSfxSet]) -> Dictionary:
	var lookup: Dictionary = {}
	for entry: StateSfxSet in p_table:
		if not Utility.is_object_valid(entry):
			continue
		lookup[entry.state_event_id] = entry
	return lookup


## Declares the 3 state ids the framework already drives (Camera/AudioMixing/
## MusicDirector); every stage starts empty (silent) - sound design is too
## game-specific to default, this just gives the Inspector a ready skeleton.
static func build_default_state_sfx_table() -> Array[StateSfxSet]:
	return [
		make_state_sfx(EventIds.STATE_HURT),
		make_state_sfx(EventIds.STATE_LOWHEALTH),
		make_state_sfx(EventIds.STATE_PAUSED),
	]


static func make_state_sfx(p_state_event_id: StringName) -> StateSfxSet:
	var entry := StateSfxSet.new()
	entry.state_event_id = p_state_event_id
	return entry


static func resolve_state_sfx(p_lookup: Dictionary, p_event_id: StringName) -> StateSfxSet:
	return p_lookup.get(p_event_id)


## `p_unit` is a random draw in 0..1 (distinct from the +/-1 convention above -
## this picks an index, it doesn't offset a value). `p_fallback_id` is returned
## when `p_ids` is empty.
static func pick_variation_id(p_ids: Array[StringName], p_fallback_id: StringName, p_unit: float) -> StringName:
	if p_ids.is_empty():
		return p_fallback_id
	var index := clampi(int(floor(clampf(p_unit, 0.0, 0.999999) * p_ids.size())), 0, p_ids.size() - 1)
	return p_ids[index]


## `p_unit` is a random value in -1..1. Returns a `pitch_scale` multiplier: at
## +/-1 it is +/- `p_semitones` from unity.
static func random_pitch_scale(p_semitones: float, p_unit: float) -> float:
	return pow(SEMITONE_RATIO_BASE, (p_unit * p_semitones) / SEMITONES_PER_OCTAVE)


## `p_unit` is a random value in -1..1. Returns a dB offset in
## +/- `p_range_db`.
static func random_volume_db(p_range_db: float, p_unit: float) -> float:
	return p_unit * p_range_db


static func should_keep_on_scene_change(p_route: SfxRoute) -> bool:
	if not Utility.is_object_valid(p_route):
		return true
	return not p_route.route_stop_on_scene_change
