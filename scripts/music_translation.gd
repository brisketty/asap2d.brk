class_name MusicTranslation
## Pure logic for the BGM & Ambience subsystem: stem-blend volumes, theme
## crossfade volumes, and stem id derivation. No engine state, unit-tested
## headless.


## Abstract asset id for stem `p_index` of theme `p_theme_id`: `"<theme>.<i>"`.
static func stem_asset_id(p_theme_id: StringName, p_index: int) -> StringName:
	return StringName("%s.%d" % [p_theme_id, p_index])


## 0..1: how "on" stem `p_index` is at the given intensity. Stem 0 fades in
## first, then 1, then 2 ... so rising intensity layers the arrangement up.
static func stem_activation(p_index: int, p_intensity: float, p_stem_count: int) -> float:
	if p_stem_count <= 0:
		return 0.0
	return clampf(p_intensity * float(p_stem_count) - float(p_index), 0.0, 1.0)


## Target volume in dB for stem `p_index`: `p_floor_db` when off, `0.0` when
## fully on, linear between.
static func stem_volume_db(
	p_index: int,
	p_intensity: float,
	p_stem_count: int,
	p_floor_db: float,
) -> float:
	return lerpf(p_floor_db, 0.0, stem_activation(p_index, p_intensity, p_stem_count))


## `{ out_db, in_db }` for a theme crossfade at `p_progress` 0..1: the old theme
## rides from `0.0` down to `p_floor_db`, the new one the other way.
static func crossfade_volumes(p_progress: float, p_floor_db: float) -> Dictionary:
	var progress := clampf(p_progress, 0.0, 1.0)
	return {
		&"out_db": lerpf(0.0, p_floor_db, progress),
		&"in_db": lerpf(p_floor_db, 0.0, progress),
	}


## One stream per stem, resolved through the theme manager. `p_theme_manager` is
## duck-typed (needs `resolve_music`).
static func resolve_stem_streams(
	p_theme_manager,
	p_theme_id: StringName,
	p_stem_count: int,
) -> Array[AudioStream]:
	var streams: Array[AudioStream] = []
	if not Utility.is_object_valid(p_theme_manager):
		return streams
	for i: int in p_stem_count:
		streams.append(p_theme_manager.resolve_music(stem_asset_id(p_theme_id, i)))
	return streams
