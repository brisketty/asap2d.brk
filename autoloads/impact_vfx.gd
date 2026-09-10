class_name ImpactVfxSubsystem
extends Node
## Impact & Combat VFX. Registered as the `ImpactVfx` autoload.
##
## Translates `impact.*` and `combat.hitstop` semantic events into pooled
## particle bursts and a single coordinated hit-stop. Hit-flash, knockback and
## squash & stretch are opt-in components (prefabs/hit_flash, knockback_receiver,
## squash_stretch) that entities attach and that listen on the Event Bus
## directly - the subsystem never looks entity nodes up.
##
## Pure translation / bookkeeping lives in `ImpactTranslation` (autoload-free,
## unit-tested headless).

## Hit-stop time scale. A tiny non-zero value rather than 0.0 so `_process` on
## always-process nodes keeps ticking; visually indistinguishable from a freeze.
const HITSTOP_TIME_SCALE := 0.0001

@export_group("Intensity", "intensity_")
## Leave empty to use `ImpactTranslation.build_default_intensity_table()`.
@export var intensity_table: Array[ImpactIntensity] = []

@export_group("Hit-stop", "hitstop_")
@export var hitstop_max_seconds: float = 0.5

var intensity_by_event_id: Dictionary = {}
var particle_burst_pool: ParticleBurstPool

var hitstop_active: bool = false
var hitstop_end_msec: int = 0


func _ready() -> void:
	rebuild_intensity_lookup()
	particle_burst_pool = ParticleBurstPool.get_packed_scene().instantiate()
	add_child(particle_burst_pool)
	EventBus.semantic_event_emitted.connect(handle_semantic_event_emitted)


func rebuild_intensity_lookup() -> void:
	var table := intensity_table
	if table.is_empty():
		table = ImpactTranslation.build_default_intensity_table()
	intensity_by_event_id = ImpactTranslation.build_lookup(table)


## The intensity row for an event id, or null.
func resolve_impact(p_event_id: StringName) -> ImpactIntensity:
	return intensity_by_event_id.get(p_event_id)


func handle_semantic_event_emitted(p_event_id: StringName, p_context: Dictionary) -> void:
	if p_event_id == EventIds.COMBAT_HITSTOP:
		request_hitstop(float(p_context.get(Utility.CONTEXT_MAGNITUDE_KEY, 0.0)))
		return
	var entry := resolve_impact(p_event_id)
	if not Utility.is_object_valid(entry):
		return
	var position: Vector2 = p_context.get(Utility.CONTEXT_POSITION_KEY, Vector2.ZERO)
	if Utility.is_object_valid(particle_burst_pool):
		particle_burst_pool.burst(position, entry.intensity_particle_asset_id, entry.intensity_particle_count)
	if entry.intensity_hitstop_seconds > 0.0:
		request_hitstop(entry.intensity_hitstop_seconds)


func request_hitstop(p_seconds: float) -> void:
	var now := Time.get_ticks_msec()
	var new_end := ImpactTranslation.compute_hitstop_end(hitstop_end_msec, now, p_seconds, hitstop_max_seconds)
	if new_end <= now:
		return
	hitstop_end_msec = new_end
	if hitstop_active:
		return
	hitstop_active = true
	Engine.time_scale = HITSTOP_TIME_SCALE
	check_hitstop()


func check_hitstop() -> void:
	var remaining_msec := hitstop_end_msec - Time.get_ticks_msec()
	if remaining_msec <= 0:
		end_hitstop()
		return
	# Real-time timer (ignore_time_scale = true) so it fires while frozen.
	var timer := get_tree().create_timer(remaining_msec / 1000.0, true, false, true)
	timer.timeout.connect(check_hitstop)


func end_hitstop() -> void:
	hitstop_active = false
	hitstop_end_msec = 0
	Engine.time_scale = 1.0
