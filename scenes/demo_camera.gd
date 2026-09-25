class_name CameraDemo
extends Node2D
## Visual harness for the Camera & Post-Processing subsystem. A wandering player
## is registered as the camera target; buttons emit the events that drive trauma
## shake, zoom and the state post-FX grade.

const WANDER_RADIUS := 140.0
const WANDER_SPEED := 1.1
const PLAYER_SOURCE_ID := &"player"

const TILE_UNDER_SIZE := Vector2i(72, 72)
const TILE_OVER_SIZE := Vector2i(40, 40)

const CHECKER_CELL_SIZE := Vector2i(64, 64)
const CHECKER_COLOR_A := Color(0.22, 0.24, 0.28)
const CHECKER_COLOR_B := Color(0.14, 0.15, 0.18)
const CHECKER_BACKGROUND_SIZE := Vector2(2000.0, 2000.0)
const CHECKER_Z_INDEX := -10

const TONE_STATE_HURT_ENTER := &"sfx.state.hurt.enter"
const TONE_STATE_HURT_LOOP := &"sfx.state.hurt.loop"
const TONE_STATE_HURT_EXIT := &"sfx.state.hurt.exit"
const TONE_CAMERA_SHAKE := &"sfx.camera.shake"
const TONE_CAMERA_ZOOM := &"sfx.camera.zoom"

@export_group("Profiles", "profile_")
@export var profile_available: Array[ThemeProfile] = []

@export_group("Nodes", "node_")
@export var node_player: Node2D
@export var node_boss_region: CameraFocusRegion
@export var node_crit_button: BaseButton
@export var node_shake_button: BaseButton
@export var node_hurt_button: BaseButton
@export var node_clear_button: BaseButton
@export var node_zoom_in_button: BaseButton
@export var node_zoom_out_button: BaseButton
@export var node_fit_mode_button: BaseButton

var wander_time: float = 0.0
var player_origin: Vector2


static func get_packed_scene() -> PackedScene:
	return load("res://scenes/demo_camera.tscn") as PackedScene


func _ready() -> void:
	inject_demo_background()
	inject_demo_screen_tiles()
	inject_demo_sounds()
	ThemeManager.profile_available = profile_available
	if not profile_available.is_empty():
		ThemeManager.set_active_profile_by_id(profile_available[0].profile_id)
	player_origin = node_player.position
	CameraDirector.set_followed(node_player)
	node_crit_button.pressed.connect(handle_node_crit_button_pressed)
	node_shake_button.pressed.connect(handle_node_shake_button_pressed)
	node_hurt_button.pressed.connect(handle_node_hurt_button_pressed)
	node_clear_button.pressed.connect(handle_node_clear_button_pressed)
	node_zoom_in_button.pressed.connect(handle_node_zoom_in_button_pressed)
	node_zoom_out_button.pressed.connect(handle_node_zoom_out_button_pressed)
	node_fit_mode_button.pressed.connect(handle_node_fit_mode_button_pressed)
	update_fit_mode_button_text()


## The framework ships no ground art either, so paint a code-built checker
## backdrop behind the player - a fixed world-space reference frame that makes
## the camera's follow, shake and zoom behavior visible as the player wanders.
func inject_demo_background() -> void:
	var background := Sprite2D.new()
	background.name = "Background"
	background.texture = build_checker_texture(CHECKER_COLOR_A, CHECKER_COLOR_B, CHECKER_CELL_SIZE)
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	background.region_enabled = true
	background.region_rect = Rect2(Vector2.ZERO, CHECKER_BACKGROUND_SIZE)
	background.centered = true
	background.position = node_player.position
	background.z_index = CHECKER_Z_INDEX
	add_child(background)
	move_child(background, 0)


func build_checker_texture(p_color_a: Color, p_color_b: Color, p_cell_size: Vector2i) -> ImageTexture:
	var image := Image.create(p_cell_size.x * 2, p_cell_size.y * 2, false, Image.FORMAT_RGB8)
	image.fill_rect(Rect2i(Vector2i.ZERO, p_cell_size), p_color_a)
	image.fill_rect(Rect2i(Vector2i(p_cell_size.x, 0), p_cell_size), p_color_b)
	image.fill_rect(Rect2i(Vector2i(0, p_cell_size.y), p_cell_size), p_color_b)
	image.fill_rect(Rect2i(p_cell_size, p_cell_size), p_color_a)
	return ImageTexture.create_from_image(image)


## The framework ships no border art, so give the Hurt state a code-built
## `ScreenTileSet` for each layer (under/over the vignette) - same spirit as
## `demo_world.gd`'s `inject_demo_parallax()`.
func inject_demo_screen_tiles() -> void:
	for profile: ThemeProfile in profile_available:
		if not Utility.is_object_valid(profile):
			continue
		var tiles := profile.screen_tile_assets
		tiles[EventIds.STATE_HURT] = build_tile_set(
			[Color(0.55, 0.05, 0.05), Color(0.35, 0.03, 0.03)], TILE_UNDER_SIZE
		)
		tiles[StringName(String(EventIds.STATE_HURT) + ".over")] = build_tile_set(
			[Color(0.95, 0.2, 0.15, 0.55), Color(0.8, 0.1, 0.05, 0.55)], TILE_OVER_SIZE
		)
		profile.screen_tile_assets = tiles


func build_tile_set(p_colors: Array[Color], p_tile_size: Vector2i) -> ScreenTileSet:
	var tile_set := ScreenTileSet.new()
	tile_set.tile_size = p_tile_size
	tile_set.border_thickness_tiles = 1
	var variations: Array[Texture2D] = []
	for color: Color in p_colors:
		variations.append(build_solid_texture(color, p_tile_size))
	tile_set.tile_variations = variations
	return tile_set


func build_solid_texture(p_color: Color, p_size: Vector2i) -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, p_color)
	gradient.set_color(1, p_color)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = p_size.x
	texture.height = p_size.y
	return texture


## The framework ships no audio either. Gives Shake/Zoom a one-shot tone and
## Hurt an enter/loop/exit tone set, same spirit as `demo_sfx.gd`'s
## `build_tone_profile()`.
func inject_demo_sounds() -> void:
	for profile: ThemeProfile in profile_available:
		if not Utility.is_object_valid(profile):
			continue
		var audio := profile.audio_assets
		audio[TONE_STATE_HURT_ENTER] = ToneStream.make(220.0, 0.18)
		audio[TONE_STATE_HURT_LOOP] = ToneStream.make(140.0, 1.0, 0.25, true)
		audio[TONE_STATE_HURT_EXIT] = ToneStream.make(260.0, 0.15)
		audio[TONE_CAMERA_SHAKE] = ToneStream.make(90.0, 0.12)
		audio[TONE_CAMERA_ZOOM] = ToneStream.make(520.0, 0.1)
		profile.audio_assets = audio

	var hurt_sfx := StateSfxSet.new()
	hurt_sfx.state_event_id = EventIds.STATE_HURT
	hurt_sfx.enter_audio_variation_ids = [TONE_STATE_HURT_ENTER]
	hurt_sfx.loop_audio_variation_ids = [TONE_STATE_HURT_LOOP]
	hurt_sfx.exit_audio_variation_ids = [TONE_STATE_HURT_EXIT]
	SfxPlayer.state_sfx_table = [hurt_sfx]
	SfxPlayer.rebuild_state_sfx_lookup()
	# SfxPlayer's default route table already maps camera.shake/camera.zoom to
	# these exact ids - just needed them mapped in the active ThemeProfile.


func _process(p_delta: float) -> void:
	wander_time += p_delta * WANDER_SPEED
	node_player.position = player_origin + Vector2(cos(wander_time), sin(wander_time * 0.7)) * WANDER_RADIUS


func handle_node_crit_button_pressed() -> void:
	EventBus.emit_semantic_event(
		EventIds.IMPACT_CRIT,
		Utility.make_spatial_context(node_player.global_position, Vector2.ZERO, 0.0, PLAYER_SOURCE_ID),
	)


func handle_node_shake_button_pressed() -> void:
	EventBus.emit_semantic_event(
		EventIds.CAMERA_SHAKE,
		Utility.make_spatial_context(Vector2.ZERO, Vector2.ZERO, 0.7),
	)


func handle_node_hurt_button_pressed() -> void:
	EventBus.emit_semantic_event(EventIds.STATE_HURT, {})


func handle_node_clear_button_pressed() -> void:
	EventBus.emit_semantic_event(EventIds.STATE_CLEAR, {})


func handle_node_zoom_in_button_pressed() -> void:
	EventBus.emit_semantic_event(EventIds.CAMERA_ZOOM, Utility.make_spatial_context(Vector2.ZERO, Vector2.ZERO, 1.6))


func handle_node_zoom_out_button_pressed() -> void:
	EventBus.emit_semantic_event(EventIds.CAMERA_ZOOM, Utility.make_spatial_context(Vector2.ZERO, Vector2.ZERO, 1.0))


## Toggles BossRegion's zoom-to-fit trade-off: CENTERED always shows the whole
## region (may reveal area outside it); COVERED never shows outside the
## region (may crop part of it). Takes effect next time the marker enters.
func handle_node_fit_mode_button_pressed() -> void:
	if not Utility.is_object_valid(node_boss_region):
		return
	node_boss_region.region_fit_mode = (
		CameraTranslation.FocusFitMode.COVERED
		if node_boss_region.region_fit_mode == CameraTranslation.FocusFitMode.CENTERED
		else CameraTranslation.FocusFitMode.CENTERED
	)
	update_fit_mode_button_text()


func update_fit_mode_button_text() -> void:
	if not Utility.is_object_valid(node_fit_mode_button) or not Utility.is_object_valid(node_boss_region):
		return
	var mode_name := (
		"CENTERED" if node_boss_region.region_fit_mode == CameraTranslation.FocusFitMode.CENTERED else "COVERED"
	)
	node_fit_mode_button.text = "focus fit: %s" % mode_name
