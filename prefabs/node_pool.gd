class_name NodePool
extends Node
## Reusable object pool. Pre-warms `pool_scene` instances, hands them out with
## `acquire()`, takes them back with `release()`. Acquired nodes are parented to
## the pool; the caller positions / reparents them as needed. Never `queue_free`
## a pooled node in an event handler - `release()` it instead.
##
## Used by the Impact VFX, SFX and UI/HUD subsystems (particle bursts, audio
## players, floating damage text).

@export_group("Pool", "pool_")
@export var pool_scene: PackedScene
@export var pool_prewarm_count: int = 0
## Hard ceiling on live instances. At the ceiling, `acquire()` recycles the
## oldest in-use node instead of instantiating.
@export var pool_max_count: int = 64

var available: Array[Node] = []
var in_use: Array[Node] = []


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/node_pool.tscn") as PackedScene


func _ready() -> void:
	prewarm()


## Instantiate up to `pool_prewarm_count` idle nodes. Idempotent-ish: tops the
## available list up to the prewarm count, never past it.
func prewarm() -> void:
	while available.size() < pool_prewarm_count:
		var node := instantiate_node()
		if not Utility.is_object_valid(node):
			return
		available.append(node)


func instantiate_node() -> Node:
	if not Utility.is_object_valid(pool_scene):
		printerr("NodePool: pool_scene is not set.")
		return null
	return pool_scene.instantiate()


## Returns a node parented to this pool, or null if `pool_scene` is unset.
func acquire() -> Node:
	var node: Node = null
	if not available.is_empty():
		node = available.pop_back()
	elif in_use.size() < pool_max_count:
		node = instantiate_node()
	elif not in_use.is_empty():
		node = in_use.pop_front()
		detach(node)
	if not Utility.is_object_valid(node):
		return null
	in_use.append(node)
	add_child(node)
	return node


func release(p_node: Node) -> void:
	if not Utility.is_object_valid(p_node):
		return
	in_use.erase(p_node)
	if available.has(p_node):
		return
	detach(p_node)
	available.append(p_node)


func detach(p_node: Node) -> void:
	if p_node.get_parent() == self:
		remove_child(p_node)


## Frees every pooled node and empties both lists. Call on teardown.
func clear_pool() -> void:
	for node: Node in available + in_use:
		if Utility.is_object_valid(node):
			node.queue_free()
	available.clear()
	in_use.clear()
