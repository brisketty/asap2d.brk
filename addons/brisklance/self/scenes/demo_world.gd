class_name WorldDemo
extends Node2D
## Visual harness for the World & Environment subsystem. Buttons emit abstract
## biome.entered / biome.exited events; the subsystem swaps the active
## ThemeProfile and rebuilds its parallax rig, ambient particles and shader
## overlay from the biome-mapped asset ids. An AnimatedTileDriver swaps the
## ground TileSet the same way. The camera pans so parallax is visible.

const CAMERA_PAN_SPEED := 40.0
const TILE_SIZE := 64
const FLOOR_ROW := 6
const FLOOR_SPAN := 24

## The framework ships no ground art; a floor row of the same repeated sprite
## reads as static rather than scrolling. A 2-tile checker (same idea as
## demo_camera.gd's checker background) makes the camera's pan actually read
## as motion instead.
const CHECKER_TILE_COORDS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
const FLOOR_CHECKER_COLORS_BY_BIOME := {
	&"forest": [Color(0.30, 0.55, 0.28), Color(0.22, 0.42, 0.20)],
	&"cave": [Color(0.34, 0.38, 0.46), Color(0.24, 0.27, 0.34)],
}

## Radial-blob parallax textures, far -> near. Bigger + fainter reads as further
## away; smaller + sharper reads as closer, so the scroll-scale split the
## subsystem applies actually looks like depth.
const PARALLAX_LAYER_SIZES: Array[Vector2i] = [
	Vector2i(320, 320), Vector2i(224, 224), Vector2i(160, 160),
]
const PARALLAX_LAYER_ALPHAS: PackedFloat32Array = [0.35, 0.6, 0.95]

## Per-biome layer tints, far -> near. Forest greens warming to a canopy
## highlight; cave slate cooling to a pale glow.
const PARALLAX_TINTS_BY_BIOME := {
	&"forest": [Color(0.20, 0.45, 0.22), Color(0.35, 0.60, 0.28), Color(0.78, 0.86, 0.34)],
	&"cave": [Color(0.16, 0.20, 0.32), Color(0.28, 0.34, 0.48), Color(0.58, 0.70, 0.88)],
}

@export_group("Profiles", "profile_")
@export var profile_available: Array[ThemeProfile] = []

@export_group("Nodes", "node_")
## CameraDirector owns the actual Camera2D; this is just what it follows,
## so panning this node is what makes the parallax rig actually scroll.
@export var node_pan_target: Node2D
@export var node_tilemap_layer: TileMapLayer
@export var node_forest_button: BaseButton
@export var node_cave_button: BaseButton
@export var node_exit_button: BaseButton
@export var node_status_label: Label


static func get_packed_scene() -> PackedScene:
	return load("res://addons/brisklance/self/scenes/demo_world.tscn") as PackedScene


func _ready() -> void:
	inject_demo_tilesets()
	inject_demo_parallax()
	ThemeManager.profile_available = profile_available
	CameraDirector.set_followed(node_pan_target)
	node_forest_button.pressed.connect(handle_node_forest_button_pressed)
	node_cave_button.pressed.connect(handle_node_cave_button_pressed)
	node_exit_button.pressed.connect(handle_node_exit_button_pressed)
	# Start inside a biome so the parallax rig, tint overlay and floor exist
	# before any button press - the subsystem only builds them on biome.entered.
	enter_biome(&"forest")


## The framework has no shipped tiles; give each biome profile a code-built
## checker TileSet keyed by `world.tiles` so the AnimatedTileDriver has
## something to swap and the floor scrolling actually reads as motion.
func inject_demo_tilesets() -> void:
	for profile: ThemeProfile in profile_available:
		if not Utility.is_object_valid(profile):
			continue
		var colors: Array = FLOOR_CHECKER_COLORS_BY_BIOME.get(
			profile.profile_id, FLOOR_CHECKER_COLORS_BY_BIOME[&"forest"]
		)
		var tilesets := profile.tileset_assets
		tilesets[&"world.tiles"] = build_checker_tileset(colors[0], colors[1])
		profile.tileset_assets = tilesets


func build_checker_tileset(p_color_a: Color, p_color_b: Color) -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source := TileSetAtlasSource.new()
	source.texture = build_checker_tile_texture(p_color_a, p_color_b)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for coords: Vector2i in CHECKER_TILE_COORDS:
		source.create_tile(coords)
	tileset.add_source(source, 0)
	return tileset


func build_checker_tile_texture(p_color_a: Color, p_color_b: Color) -> ImageTexture:
	var image := Image.create(TILE_SIZE * CHECKER_TILE_COORDS.size(), TILE_SIZE, false, Image.FORMAT_RGB8)
	for index: int in CHECKER_TILE_COORDS.size():
		var color := p_color_a if index % 2 == 0 else p_color_b
		image.fill_rect(Rect2i(Vector2i(TILE_SIZE * index, 0), Vector2i(TILE_SIZE, TILE_SIZE)), color)
	return ImageTexture.create_from_image(image)


## The framework ships no parallax art, so every `world.parallax.*` id resolves
## to `res://icon.svg` and all three layers look identical. Give each biome
## profile distinct radial-blob textures per layer so depth and biome swaps read.
func inject_demo_parallax() -> void:
	var layer_ids := WorldEnvironment2DSubsystem.PARALLAX_LAYER_IDS
	for profile: ThemeProfile in profile_available:
		if not Utility.is_object_valid(profile):
			continue
		var tints: Array = PARALLAX_TINTS_BY_BIOME.get(
			profile.profile_id, PARALLAX_TINTS_BY_BIOME[&"forest"]
		)
		var sprites := profile.sprite_assets
		for index: int in layer_ids.size():
			var tint: Color = tints[index]
			sprites[StringName(layer_ids[index])] = build_parallax_texture(
				tint, PARALLAX_LAYER_SIZES[index], PARALLAX_LAYER_ALPHAS[index]
			)
		profile.sprite_assets = sprites


func build_parallax_texture(p_tint: Color, p_size: Vector2i, p_center_alpha: float) -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(p_tint.r, p_tint.g, p_tint.b, p_center_alpha))
	gradient.set_color(1, Color(p_tint.r, p_tint.g, p_tint.b, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = p_size.x
	texture.height = p_size.y
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 1.0)
	return texture


func refresh_status(p_biome_id: StringName) -> void:
	if not Utility.is_object_valid(node_status_label):
		return
	node_status_label.text = "Biome: %s" % (String(p_biome_id) if p_biome_id != &"" else "(none)")


func paint_floor() -> void:
	if not Utility.is_object_valid(node_tilemap_layer.tile_set):
		return
	for x: int in FLOOR_SPAN:
		var coords: Vector2i = CHECKER_TILE_COORDS[x % CHECKER_TILE_COORDS.size()]
		node_tilemap_layer.set_cell(Vector2i(x - FLOOR_SPAN / 2, FLOOR_ROW), 0, coords)


func _process(p_delta: float) -> void:
	node_pan_target.position.x += CAMERA_PAN_SPEED * p_delta


func enter_biome(p_biome_id: StringName) -> void:
	EventBus.emit_semantic_event(
		EventIds.BIOME_ENTERED,
		Utility.make_spatial_context(Vector2.ZERO, Vector2.ZERO, 0.0, p_biome_id),
	)
	repaint_floor_for_active_tileset()
	refresh_status(p_biome_id)


func repaint_floor_for_active_tileset() -> void:
	node_tilemap_layer.clear()
	paint_floor()


func handle_node_forest_button_pressed() -> void:
	enter_biome(&"forest")


func handle_node_cave_button_pressed() -> void:
	enter_biome(&"cave")


func handle_node_exit_button_pressed() -> void:
	EventBus.emit_semantic_event(EventIds.BIOME_EXITED, {})
	node_tilemap_layer.clear()
	refresh_status(&"")
