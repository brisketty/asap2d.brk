class_name HudPolishSubsystem
extends Node
## UI & HUD Polish. Registered as the `HudPolish` autoload.
##
## Spawns pooled world-space floating damage / heal numbers on `damage.*` events.
## Catch-up bars and hover pops are self-contained prefabs a HUD scene drops in;
## the subsystem offers a thin `register_bar` / `push_bar_ratio` convenience so a
## game can route `damage.*` to a bar by id if it wants.
##
## Number formatting / colour lives in `HudTranslation`.

var text_pool: NodePool
var bars_by_id: Dictionary = {}


func _ready() -> void:
	text_pool = NodePool.get_packed_scene().instantiate()
	text_pool.pool_scene = FloatingDamageText.get_packed_scene()
	text_pool.pool_prewarm_count = 8
	text_pool.pool_max_count = 48
	add_child(text_pool)
	text_pool.prewarm()
	EventBus.semantic_event_emitted.connect(handle_semantic_event_emitted)


func handle_semantic_event_emitted(p_event_id: StringName, p_context: Dictionary) -> void:
	if p_event_id != EventIds.DAMAGE_DEALT and p_event_id != EventIds.DAMAGE_HEALED:
		return
	var magnitude: float = p_context.get(Utility.CONTEXT_MAGNITUDE_KEY, 0.0)
	var position: Vector2 = p_context.get(Utility.CONTEXT_POSITION_KEY, Vector2.ZERO)
	spawn_floating_text(
		HudTranslation.damage_text(magnitude, p_event_id),
		HudTranslation.damage_color(magnitude, p_event_id),
		position,
	)
	var bar_id: StringName = p_context.get(Utility.CONTEXT_SOURCE_ID_KEY, &"")
	if bar_id != &"" and p_context.has(&"ratio"):
		push_bar_ratio(bar_id, float(p_context[&"ratio"]))


func spawn_floating_text(p_text: String, p_color: Color, p_global_position: Vector2) -> void:
	if not Utility.is_object_valid(text_pool):
		return
	var text := text_pool.acquire() as FloatingDamageText
	if not Utility.is_object_valid(text):
		return
	text.global_position = p_global_position
	text.finished.connect(release_floating_text.bind(text), CONNECT_ONE_SHOT)
	text.play(p_text, p_color)


func release_floating_text(p_text: FloatingDamageText) -> void:
	if Utility.is_object_valid(text_pool):
		text_pool.release(p_text)


## A HUD scene registers its bar so the game can push ratios to it by id.
func register_bar(p_bar_id: StringName, p_bar: CatchUpBar) -> void:
	if not Utility.is_object_valid(p_bar):
		return
	bars_by_id[p_bar_id] = p_bar


func unregister_bar(p_bar_id: StringName) -> void:
	bars_by_id.erase(p_bar_id)


func push_bar_ratio(p_bar_id: StringName, p_ratio: float) -> void:
	var bar := bars_by_id.get(p_bar_id) as CatchUpBar
	if Utility.is_object_valid(bar):
		bar.set_ratio(p_ratio)
