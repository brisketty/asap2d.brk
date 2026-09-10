class_name HudTranslation
## Pure logic for the UI & HUD Polish subsystem: damage-number formatting,
## colour tiers, and the catch-up-bar lerp step. No engine state, unit-tested
## headless.

const SNAP_EPSILON := 0.001

## Magnitude thresholds for the damage-number colour tiers.
const TIER_LIGHT := 10.0
const TIER_HEAVY := 25.0

const COLOR_HEAL := Color(0.4, 0.9, 0.4)
const COLOR_LIGHT := Color(0.95, 0.95, 0.95)
const COLOR_HEAVY := Color(1.0, 0.6, 0.2)
const COLOR_SEVERE := Color(1.0, 0.3, 0.25)


static func is_heal(p_event_id: StringName) -> bool:
	return p_event_id == EventIds.DAMAGE_HEALED


## "12" for damage, "+5" for a heal. Magnitude is rounded to a whole number.
static func damage_text(p_magnitude: float, p_event_id: StringName) -> String:
	var amount := roundi(absf(p_magnitude))
	if is_heal(p_event_id):
		return "+%d" % amount
	return str(amount)


static func damage_color(p_magnitude: float, p_event_id: StringName) -> Color:
	if is_heal(p_event_id):
		return COLOR_HEAL
	var amount := absf(p_magnitude)
	if amount < TIER_LIGHT:
		return COLOR_LIGHT
	if amount < TIER_HEAVY:
		return COLOR_HEAVY
	return COLOR_SEVERE


## Move `p_current` toward `p_target` by at most `p_speed * p_delta` ratio units,
## snapping when within one step (or `SNAP_EPSILON`).
static func catch_up_step(p_current: float, p_target: float, p_speed: float, p_delta: float) -> float:
	var max_step := p_speed * p_delta
	var diff := p_target - p_current
	if absf(diff) <= max_step or absf(diff) < SNAP_EPSILON:
		return p_target
	return p_current + signf(diff) * max_step
