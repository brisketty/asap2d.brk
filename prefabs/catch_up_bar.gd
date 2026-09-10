class_name CatchUpBar
extends Control
## A health / mana bar with a trailing "ghost" fill: the front bar snaps to the
## pushed value, the trail bar eases toward it (fast on heal, laggy on damage
## so the hit reads). The owning HUD pushes a 0..1 ratio via `set_ratio()`.

@export_group("Catch-up", "catch_up_")
## Ratio units per second the trail bar closes the gap.
@export var catch_up_speed: float = 1.4
## The trail snaps forward instantly on a heal (so it never lags *behind* growth).
@export var catch_up_snap_on_heal: bool = true

@export_group("Nodes", "node_")
@export var node_front_bar: Range
@export var node_trail_bar: Range

var target_ratio: float = 1.0
var trail_ratio: float = 1.0


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/catch_up_bar.tscn") as PackedScene


func _ready() -> void:
	set_ratio(target_ratio)


func set_ratio(p_value: float) -> void:
	var clamped := clampf(p_value, 0.0, 1.0)
	var is_heal := clamped > target_ratio
	target_ratio = clamped
	if Utility.is_object_valid(node_front_bar):
		node_front_bar.value = target_ratio
	if is_heal and catch_up_snap_on_heal:
		trail_ratio = target_ratio
		apply_trail()


func _process(p_delta: float) -> void:
	if is_equal_approx(trail_ratio, target_ratio):
		return
	trail_ratio = HudTranslation.catch_up_step(trail_ratio, target_ratio, catch_up_speed, p_delta)
	apply_trail()


func apply_trail() -> void:
	if Utility.is_object_valid(node_trail_bar):
		node_trail_bar.value = trail_ratio
