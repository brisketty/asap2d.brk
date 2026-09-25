extends SceneTree

const ThemeManagerScript := preload("res://addons/brisklance/self/autoloads/theme_manager.gd")


func make_profile(p_id: StringName, p_sprites: Dictionary, p_default: Texture2D) -> ThemeProfile:
	var profile := ThemeProfile.new()
	profile.profile_id = p_id
	profile.sprite_assets = p_sprites
	profile.default_sprite = p_default
	return profile


func _initialize() -> void:
	var failure_count := 0

	var mapped_texture := PlaceholderTexture2D.new()
	var profile_default_texture := PlaceholderTexture2D.new()

	var manager: Node = ThemeManagerScript.new()
	var engine_fallback: Texture2D = manager.profile_fallback_sprite
	failure_count += expect_true("engine fallback sprite configured", Utility.is_object_valid(engine_fallback))

	var changed_ids: Array[StringName] = []
	manager.active_profile_changed.connect(func(p_id: StringName) -> void: changed_ids.append(p_id))

	var complete := make_profile(&"complete", {&"impact.spark": mapped_texture}, profile_default_texture)
	var sparse := make_profile(&"sparse", {}, null)

	manager.active_profile = complete
	failure_count += expect_true("profile-changed signal fired", changed_ids == ([&"complete"] as Array[StringName]))
	failure_count += expect_true("mapped id resolves to mapped texture", manager.resolve_sprite(&"impact.spark") == mapped_texture)
	failure_count += expect_true("missing id falls back to profile default", manager.resolve_sprite(&"nope") == profile_default_texture)
	failure_count += expect_true("has_sprite true for mapped", manager.has_sprite(&"impact.spark"))
	failure_count += expect_true("has_sprite false for missing", not manager.has_sprite(&"nope"))

	manager.active_profile = sparse
	failure_count += expect_true("missing profile default falls back to engine fallback", manager.resolve_sprite(&"nope") == engine_fallback)
	failure_count += expect_true("resolve_sprite never null", Utility.is_object_valid(manager.resolve_sprite(&"anything")))
	failure_count += expect_true("resolve_audio null when no fallback set", manager.resolve_audio(&"anything") == null)

	# music: 6th kind, same ladder via the generic helper
	var music_stream := AudioStreamWAV.new()
	var music_profile := ThemeProfile.new()
	music_profile.profile_id = &"scored"
	music_profile.music_assets = {&"music.theme.forest": music_stream}
	manager.active_profile = music_profile
	failure_count += expect_true("mapped music resolves", manager.resolve_music(&"music.theme.forest") == music_stream)
	failure_count += expect_true("has_music true for mapped", manager.has_music(&"music.theme.forest"))
	failure_count += expect_true("has_music false for missing", not manager.has_music(&"music.theme.cave"))
	failure_count += expect_true("missing music with no default -> null", manager.resolve_music(&"music.theme.cave") == null)

	# no active profile: straight to engine fallback, no crash
	manager.active_profile = null
	failure_count += expect_true("no profile -> engine sprite fallback", manager.resolve_sprite(&"x") == engine_fallback)
	failure_count += expect_true("no profile -> has_sprite false", not manager.has_sprite(&"x"))

	manager.free()

	if failure_count > 0:
		push_error("%d theme-manager test(s) failed." % failure_count)
		quit(1)
		return
	print("All theme-manager tests passed.")
	quit(0)


func expect_true(p_label: String, p_actual: bool) -> int:
	if p_actual:
		print("  ok: %s" % p_label)
		return 0
	push_error("  FAIL: %s" % p_label)
	return 1
