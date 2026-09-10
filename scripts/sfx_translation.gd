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
	]


static func make_route(
	p_event_id: StringName,
	p_audio_asset_id: StringName,
	p_spatialized: bool,
	p_pitch_semitones: float,
	p_volume_db_range: float,
) -> SfxRoute:
	var route := SfxRoute.new()
	route.route_event_id = p_event_id
	route.route_audio_asset_id = p_audio_asset_id
	route.route_spatialized = p_spatialized
	route.route_pitch_semitones = p_pitch_semitones
	route.route_volume_db_range = p_volume_db_range
	return route


static func resolve_route(p_lookup: Dictionary, p_event_id: StringName) -> SfxRoute:
	return p_lookup.get(p_event_id)


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
