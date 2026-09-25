class_name SfxVoicePool
extends Node
## A pool of one-shot audio voices (either `AudioStreamPlayer2D` or
## `AudioStreamPlayer`, per `pool_voice_scene`). `play()` acquires a voice,
## configures it, plays it and auto-releases it on `finished`. Used by
## SfxPlayer for the positional and dry/UI pools.

@export_group("Pool", "pool_")
@export var pool_voice_scene: PackedScene
@export var pool_prewarm_count: int = 8
@export var pool_max_count: int = 32

var node_pool: NodePool


static func get_packed_scene() -> PackedScene:
	return load("res://addons/brisklance/self/prefabs/sfx_voice_pool.tscn") as PackedScene


func _ready() -> void:
	node_pool = NodePool.get_packed_scene().instantiate()
	node_pool.pool_scene = pool_voice_scene
	node_pool.pool_prewarm_count = pool_prewarm_count
	node_pool.pool_max_count = pool_max_count
	add_child(node_pool)


## Returns the playing voice, or null if the stream is missing or the pool is
## exhausted. `p_keep_on_scene_change` tags the voice so `stop_transient()` can
## tell footsteps (cut) from explosions (play out).
func play(
	p_stream: AudioStream,
	p_pitch_scale: float,
	p_volume_db: float,
	p_global_position: Vector2,
	p_keep_on_scene_change: bool,
) -> Node:
	if not Utility.is_object_valid(p_stream) or not Utility.is_object_valid(node_pool):
		return null
	var voice := node_pool.acquire()
	if not Utility.is_object_valid(voice):
		return null
	voice.set(&"stream", p_stream)
	voice.set(&"pitch_scale", p_pitch_scale)
	voice.set(&"volume_db", p_volume_db)
	voice.set_meta(&"keep_on_scene_change", p_keep_on_scene_change)
	var voice_2d := voice as Node2D
	if voice_2d != null:
		voice_2d.global_position = p_global_position
	voice.call(&"play")
	voice.connect(&"finished", release.bind(voice), CONNECT_ONE_SHOT)
	return voice


func release(p_voice: Node) -> void:
	if not Utility.is_object_valid(p_voice):
		return
	p_voice.call(&"stop")
	if Utility.is_object_valid(node_pool):
		node_pool.release(p_voice)


## Cut every in-flight voice not tagged to play through a scene change.
func stop_transient() -> void:
	if not Utility.is_object_valid(node_pool):
		return
	for voice: Node in node_pool.in_use.duplicate():
		if not Utility.is_object_valid(voice):
			continue
		if voice.get_meta(&"keep_on_scene_change", true):
			continue
		release(voice)
