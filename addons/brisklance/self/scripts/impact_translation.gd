class_name ImpactTranslation
## Pure translation logic for the Impact & Combat VFX subsystem: intensity-table
## lookup and hit-stop bookkeeping. No engine state, no autoload references, so
## it is unit-testable headless. `ImpactVfxSubsystem` is the thin Node wrapper.

## The later of the current hit-stop end and `now + clamp(requested, 0, max)`,
## in msec. A zero (or negative) request leaves the current end untouched, so a
## short request never shortens an active hit-stop.
static func compute_hitstop_end(
	p_current_end_msec: int,
	p_now_msec: int,
	p_requested_seconds: float,
	p_max_seconds: float,
) -> int:
	var clamped := clampf(p_requested_seconds, 0.0, p_max_seconds)
	if clamped <= 0.0:
		return p_current_end_msec
	return maxi(p_current_end_msec, p_now_msec + int(clamped * 1000.0))


## `intensity_event_id -> ImpactIntensity`. Invalid rows are skipped; later rows
## win on a duplicate id.
static func build_lookup(p_table: Array[ImpactIntensity]) -> Dictionary:
	var lookup: Dictionary = {}
	for entry: ImpactIntensity in p_table:
		if not Utility.is_object_valid(entry):
			continue
		lookup[entry.intensity_event_id] = entry
	return lookup


static func build_default_intensity_table() -> Array[ImpactIntensity]:
	return [
		make_intensity(EventIds.IMPACT_BASIC, &"impact.spark", 8, 0.0),
		make_intensity(EventIds.IMPACT_HEAVY, &"impact.spark", 18, 0.08),
		make_intensity(EventIds.IMPACT_CRIT, &"impact.spark", 30, 0.14),
		make_intensity(EventIds.IMPACT_BLOCK, &"impact.spark", 6, 0.04),
	]


static func make_intensity(
	p_event_id: StringName,
	p_particle_asset_id: StringName,
	p_count: int,
	p_hitstop_seconds: float,
) -> ImpactIntensity:
	var entry := ImpactIntensity.new()
	entry.intensity_event_id = p_event_id
	entry.intensity_particle_asset_id = p_particle_asset_id
	entry.intensity_particle_count = p_count
	entry.intensity_hitstop_seconds = p_hitstop_seconds
	return entry
