class_name TuningProfile
extends Resource
## A swappable set of framework timing/threshold constants (e.g. "default" vs
## "cinematic" vs "fast-paced"). Every field's default equals the framework's
## original hardcoded value, so a bare `TuningProfile.new()` already reproduces
## today's behavior - unlike `ThemeProfile`'s asset dictionaries, no
## `build_default_*()` factory is needed.

@export var profile_id: StringName = &"default"

@export_group("Camera", "camera_")
@export var camera_zoom_tween_seconds: float = 0.35
@export var camera_focus_tween_seconds: float = 0.5
@export var camera_post_fx_fade_seconds: float = 0.4
@export var camera_focus_idle_color: Color = Color(0.3, 0.75, 1.0, 0.6)
@export var camera_focus_active_color: Color = Color(1.0, 0.65, 0.15, 0.9)
@export var camera_focus_border_width: float = 3.0
@export var camera_focus_default_region_size: Vector2 = Vector2(640.0, 360.0)
@export var camera_fit_zoom_margin: float = 1.1
## Fallback fade duration for a screen effect (`ScreenTileBorder`/
## `ScreenShaderOverlay`) whose `fade_to()` caller doesn't pass `p_seconds`.
@export var camera_screen_effect_default_fade_seconds: float = 0.35
@export var camera_shake_decay_per_second: float = 1.2
@export var camera_shake_max_offset: Vector2 = Vector2(24.0, 16.0)
@export var camera_shake_max_roll: float = 0.06
@export var camera_shake_noise_speed: float = 34.0
## Multiplies the final shake offset/rotation. One knob to make every shake
## punchier or softer without retuning `CameraDirector.trauma_table`.
@export var camera_shake_intensity_scale: float = 1.0

@export_group("Audio", "audio_")
@export var audio_mix_tween_seconds: float = 1.5
@export var audio_music_intensity_tween_seconds: float = 0.5
@export var audio_music_crossfade_seconds: float = 2.0
@export var audio_music_stem_floor_db: float = -40.0
@export var audio_spatial_max_distance: float = 2000.0
@export var audio_spatial_attenuation: float = 1.0
@export_range(0.0, 3.0) var audio_spatial_panning_strength: float = 1.0

@export_group("Vfx", "vfx_")
## Hit-stop time scale. Must stay > 0.0 (STATE.md R7) - a true 0.0 freezes
## `_process` delta, so the restore timer's delta-based logic never fires.
## `ImpactVfxSubsystem` clamps with a floor const even if a profile sets 0.
@export var vfx_hitstop_time_scale: float = 0.0001
@export var vfx_knockback_lurch_seconds: float = 0.06
@export var vfx_knockback_strength: float = 1.0
@export var vfx_knockback_recover_seconds: float = 0.25
@export var vfx_particle_release_grace_seconds: float = 0.15

@export_group("World", "world_")
@export var world_scroll_scale_min: float = 0.15
@export var world_scroll_scale_max: float = 1.0

@export_group("Ui", "ui_")
@export var ui_floating_text_lifetime_seconds: float = 0.75
@export var ui_floating_text_rise_pixels: float = 52.0
@export var ui_pop_overshoot: float = 1.25
@export var ui_pop_seconds: float = 0.22
@export var ui_fade_out_seconds: float = 0.3
@export var ui_rise_and_fade_pixels: float = 48.0
@export var ui_rise_and_fade_seconds: float = 0.7
@export var ui_shake_pixels: float = 6.0
@export var ui_shake_seconds: float = 0.3
