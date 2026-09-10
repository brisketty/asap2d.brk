class_name DemoImpactPresenter
extends Node2D
## Minimal reference presenter that proves the A.S.A.P. pipeline end to end:
## it listens on the Global Event Bus for an abstract event id and translates it
## into a sprite fetched from the ThemeManager by an abstract asset id. It is a
## demonstration, not one of the seven production subsystems.

const SPAWN_LIFETIME_SECONDS := 0.4

@export_group("Assets", "asset_")
@export var asset_spark_sprite_asset_id: StringName = &"impact.spark"

@export_group("Events", "event_")
@export var event_impact_event_id: StringName = EventIds.IMPACT_BASIC

@export_group("Nodes", "node_")
@export var node_status_label: Label


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/demo_impact_presenter.tscn") as PackedScene


func _ready() -> void:
	EventBus.semantic_event_emitted.connect(handle_semantic_event_emitted)


func handle_semantic_event_emitted(p_event_id: StringName, p_context: Dictionary) -> void:
	if p_event_id != event_impact_event_id:
		return
	var texture := ThemeManager.resolve_sprite(asset_spark_sprite_asset_id)
	var position: Vector2 = p_context.get(Utility.CONTEXT_POSITION_KEY, Vector2.ZERO)
	spawn_sprite(texture, position)
	if Utility.is_object_valid(node_status_label):
		var resolved := ThemeManager.has_sprite(asset_spark_sprite_asset_id)
		var state_text := "resolved" if resolved else "fallback"
		node_status_label.text = "%s: %s" % [state_text, asset_spark_sprite_asset_id]


func spawn_sprite(p_texture: Texture2D, p_global_position: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = p_texture
	add_child(sprite)
	sprite.global_position = p_global_position
	var timer := get_tree().create_timer(SPAWN_LIFETIME_SECONDS)
	timer.timeout.connect(func() -> void:
		if Utility.is_object_valid(sprite):
			sprite.queue_free())
