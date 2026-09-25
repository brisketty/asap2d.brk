class_name SfxRoute
extends Resource
## One row of the SFX route table: how a semantic event maps to a pooled sound.
## Designer-tunable as a typed array on the SfxPlayer subsystem.

@export var route_event_id: StringName = &"impact.basic"
## Resolved through ThemeManager.resolve_audio at play time. The fallback used
## when `route_audio_variation_ids` is empty.
@export var route_audio_asset_id: StringName = &"sfx.impact"
## Optional pool of alternate audio ids; one is picked at random per play for
## extra variety on top of the pitch/volume jitter below. Empty -> always
## `route_audio_asset_id`. Not currently visible to `AssetIdScanner` (it only
## scans single-id properties, not collections) - list these ids by hand until
## that's extended.
@export var route_audio_variation_ids: Array[StringName] = []
## true -> positional AudioStreamPlayer2D on the SFX bus; false -> dry
## AudioStreamPlayer on the UI bus.
@export var route_spatialized: bool = true
## Random pitch is +/- this many semitones.
@export var route_pitch_semitones: float = 2.0
## Random gain is +/- this many dB.
@export var route_volume_db_range: float = 3.0
## When true, an in-flight voice from this route is cut on a scene change;
## otherwise it plays out.
@export var route_stop_on_scene_change: bool = false
