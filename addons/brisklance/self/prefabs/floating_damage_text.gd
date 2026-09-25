class_name FloatingDamageText
extends Node2D
## A single world-space damage / heal number that rises and fades, then reports
## `finished` so the pool can reclaim it. Pooled and driven by HudPolish.

signal finished

@export_group("Nodes", "node_")
@export var node_label: Label

var active_tween: Tween


static func get_packed_scene() -> PackedScene:
	return load("res://addons/brisklance/self/prefabs/floating_damage_text.tscn") as PackedScene


func play(p_text: String, p_color: Color) -> void:
	if not Utility.is_object_valid(node_label):
		finished.emit()
		return
	if Utility.is_object_valid(active_tween):
		active_tween.kill()
	node_label.text = p_text
	node_label.modulate = p_color
	modulate.a = 1.0
	active_tween = Tweens.rise_and_fade(
		self, Tuning.active_profile.ui_floating_text_rise_pixels, Tuning.active_profile.ui_floating_text_lifetime_seconds
	)
	active_tween.chain().tween_callback(emit_finished)


func emit_finished() -> void:
	finished.emit()
