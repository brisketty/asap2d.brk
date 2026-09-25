class_name WorldTranslation
## Pure logic for the World & Environment subsystem: parallax scroll-scale
## distribution and layer-texture resolution. Autoload-free so it is unit-tested
## headless; `WorldEnvironment2DSubsystem` is the Node wrapper.


## One scroll scale per parallax layer, from `p_min_scale` (farthest, index 0) to
## `p_max_scale` (nearest, last index), linearly spaced. Count 0 -> empty; count
## 1 -> just `p_max_scale`.
static func build_scroll_scales(
	p_layer_count: int,
	p_min_scale: float,
	p_max_scale: float,
) -> PackedFloat32Array:
	var scales := PackedFloat32Array()
	if p_layer_count <= 0:
		return scales
	if p_layer_count == 1:
		scales.append(p_max_scale)
		return scales
	for i: int in p_layer_count:
		scales.append(lerpf(p_min_scale, p_max_scale, float(i) / float(p_layer_count - 1)))
	return scales


## One Texture2D per layer id, in order, resolved through the theme manager.
## `p_theme_manager` is duck-typed (needs `resolve_sprite`); resolve_sprite never
## returns null, so neither does this.
static func resolve_layer_textures(p_theme_manager, p_layer_ids: PackedStringArray) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	if not Utility.is_object_valid(p_theme_manager):
		return textures
	for layer_id: String in p_layer_ids:
		textures.append(p_theme_manager.resolve_sprite(StringName(layer_id)))
	return textures


## True when a biome change should drive a theme-profile switch: a non-empty id
## that differs from the currently active one.
static func should_switch_profile(p_active_profile_id: StringName, p_biome_id: StringName) -> bool:
	if p_biome_id == &"":
		return false
	return p_biome_id != p_active_profile_id
