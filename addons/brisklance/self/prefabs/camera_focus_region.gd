class_name CameraFocusRegion
extends Control
## Marks a region of interest in a scene - e.g. a boss arena. When
## `node_watched` (usually the followed player) enters this node's own rect
## (`position`/`size`, top-left anchored), it emits `camera.focus` with a
## region context so `CameraDirector` tweens the camera to frame the area per
## `region_fit_mode`; leaving the rectangle releases the focus back to
## following `node_watched` at normal zoom.
##
## Extends `Control` (like `ReferenceRect`) specifically so the rect is
## editable via Godot's native resize handles the moment this node is
## selected in the 2D editor - no override code, no child collision node.
## `Control`s compose fine under a plain `Node2D` parent and respect the same
## `Camera2D` transform, so this still behaves as a world-space marker; the
## prefab's `mouse_filter` opts it out of receiving mouse input.

@export_group("Region", "region_")
## Draw the region's bounds as an outline at runtime too - handy to confirm
## it matches what was authored in the editor. Purely visual; detection works
## either way.
@export var region_debug_draw: bool = true
## `CENTERED` (default) always shows the whole region, possibly revealing area
## outside it; `COVERED` never shows outside the region, possibly cropping
## part of it. See `CameraTranslation.FocusFitMode`.
@export var region_fit_mode: CameraTranslation.FocusFitMode = CameraTranslation.FocusFitMode.CENTERED

@export_group("Nodes", "node_")
@export var node_watched: Node2D

var is_watched_inside: bool = false


static func get_packed_scene() -> PackedScene:
	return load("res://addons/brisklance/self/prefabs/camera_focus_region.tscn") as PackedScene


func _ready() -> void:
	set_process(true)
	queue_redraw()


func _process(p_delta: float) -> void:
	if not Utility.is_object_valid(node_watched):
		return
	var region_center := global_position + size * 0.5
	var inside := CameraTranslation.is_point_in_region(node_watched.global_position, region_center, size)
	if inside == is_watched_inside:
		return
	is_watched_inside = inside
	queue_redraw()
	if inside:
		var context := Utility.make_region_context(region_center, size)
		context[Utility.CONTEXT_FIT_MODE_KEY] = region_fit_mode
		EventBus.emit_semantic_event(EventIds.CAMERA_FOCUS, context)
		return
	EventBus.emit_semantic_event(EventIds.CAMERA_FOCUS, {})


func _draw() -> void:
	if not region_debug_draw:
		return
	var color := Tuning.active_profile.camera_focus_active_color if is_watched_inside else Tuning.active_profile.camera_focus_idle_color
	draw_rect(Rect2(Vector2.ZERO, size), color, false, Tuning.active_profile.camera_focus_border_width)
