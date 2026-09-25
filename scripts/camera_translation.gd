class_name CameraTranslation
## Pure logic for the Camera & Post-Processing subsystem: trauma-shake math and
## the event -> trauma table. No engine state (the CameraRig owns the trauma
## accumulator and feeds noise samples in), so it is unit-tested headless.

# --- trauma-shake math ---

## Trauma accumulates and is clamped to 0..1.
static func add_trauma(p_current: float, p_amount: float) -> float:
	return clampf(p_current + p_amount, 0.0, 1.0)


## Linear decay toward 0, never below.
static func decay_trauma(p_current: float, p_decay_per_second: float, p_delta: float) -> float:
	return maxf(p_current - p_decay_per_second * p_delta, 0.0)


## Shake scales with trauma squared, so low trauma barely moves the camera and
## high trauma is dramatic.
static func shake_amount(p_trauma: float) -> float:
	return p_trauma * p_trauma


## `p_noise_x` / `p_noise_y` are noise samples in -1..1. `p_intensity_scale`
## multiplies the final result - a single knob (`Tuning.active_profile.camera_shake_intensity_scale`)
## to make every shake punchier/softer without retuning the trauma table.
static func compute_offset(
	p_trauma: float,
	p_max_offset: Vector2,
	p_noise_x: float,
	p_noise_y: float,
	p_intensity_scale: float = 1.0,
) -> Vector2:
	var amount := shake_amount(p_trauma) * p_intensity_scale
	return Vector2(p_max_offset.x * amount * p_noise_x, p_max_offset.y * amount * p_noise_y)


static func compute_rotation(
	p_trauma: float,
	p_max_roll: float,
	p_noise_r: float,
	p_intensity_scale: float = 1.0,
) -> float:
	return p_max_roll * shake_amount(p_trauma) * p_intensity_scale * p_noise_r


# --- event -> trauma table ---

static func build_lookup(p_table: Array[CameraTrauma]) -> Dictionary:
	var lookup: Dictionary = {}
	for entry: CameraTrauma in p_table:
		if not Utility.is_object_valid(entry):
			continue
		lookup[entry.trauma_event_id] = entry.trauma_amount
	return lookup


static func build_default_trauma_table() -> Array[CameraTrauma]:
	return [
		make_trauma(EventIds.IMPACT_HEAVY, 0.35),
		make_trauma(EventIds.IMPACT_CRIT, 0.75),
		make_trauma(EventIds.COMBAT_HITSTOP, 0.2),
		make_trauma(EventIds.COMBAT_DEATH, 0.85),
	]


static func make_trauma(p_event_id: StringName, p_amount: float) -> CameraTrauma:
	var entry := CameraTrauma.new()
	entry.trauma_event_id = p_event_id
	entry.trauma_amount = p_amount
	return entry


## Trauma amount for an event id, or 0.0 when the table has no row for it.
static func resolve_trauma(p_lookup: Dictionary, p_event_id: StringName) -> float:
	return p_lookup.get(p_event_id, 0.0)


# --- region of interest (zoom-to-fit focus) ---

## `true` when `p_point` falls inside the rectangle centered on
## `p_region_center` sized `p_region_size` - the trigger check for
## `CameraFocusRegion`, no physics bodies involved.
static func is_point_in_region(p_point: Vector2, p_region_center: Vector2, p_region_size: Vector2) -> bool:
	var rect := Rect2(p_region_center - p_region_size * 0.5, p_region_size)
	return rect.has_point(p_point)


## The uniform `Camera2D.zoom` value that frames `p_region_size` inside
## `p_viewport_size` (Godot's zoom convention: values above 1 show *more*
## world, i.e. zoom out). `p_margin` pads the fit so the region's edges aren't
## flush with the screen edge. Never zooms in past 1.0 just because the region
## is smaller than the viewport.
static func compute_fit_zoom(p_viewport_size: Vector2, p_region_size: Vector2, p_margin: float = 1.1) -> float:
	if p_viewport_size.x <= 0.0 or p_viewport_size.y <= 0.0:
		return 1.0
	var fit := maxf(p_region_size.x / p_viewport_size.x, p_region_size.y / p_viewport_size.y)
	return maxf(fit * p_margin, 1.0)
