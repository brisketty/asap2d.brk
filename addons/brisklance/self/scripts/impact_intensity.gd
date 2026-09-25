class_name ImpactIntensity
extends Resource
## One row of the Impact & Combat VFX intensity table: how a single impact.*
## semantic event id translates into concrete VFX parameters. Designer-tunable
## as a typed array on the ImpactVfx subsystem.

@export var intensity_event_id: StringName = &"impact.basic"
## Resolved through ThemeManager.resolve_particle at burst time.
@export var intensity_particle_asset_id: StringName = &"impact.spark"
@export var intensity_particle_count: int = 8
## Real-time seconds of hit-stop this impact requests (0 = none). Clamped to the
## subsystem's hitstop_max_seconds.
@export var intensity_hitstop_seconds: float = 0.0
