class_name ParticleBurstPool
extends Node
## Pooled one-shot particle bursts. Wraps a NodePool of `particle_burst.tscn`
## (a one-shot GPUParticles2D). The Impact VFX subsystem calls `burst()`; the
## burst node is released back to the pool after its lifetime.

@export_group("Nodes", "node_")
@export var node_pool: NodePool


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/particle_burst_pool.tscn") as PackedScene


func burst(p_position: Vector2, p_particle_asset_id: StringName, p_amount: int) -> void:
	if not Utility.is_object_valid(node_pool):
		printerr("ParticleBurstPool: node_pool is not set.")
		return
	var particles := node_pool.acquire() as GPUParticles2D
	if not Utility.is_object_valid(particles):
		return
	particles.global_position = p_position
	particles.amount = maxi(p_amount, 1)

	var resolved := ThemeManager.resolve_particle(p_particle_asset_id)
	var process_material := resolved as ParticleProcessMaterial
	if Utility.is_object_valid(process_material):
		particles.process_material = process_material

	particles.restart()
	particles.emitting = true

	var lifetime: float = particles.lifetime + Tuning.active_profile.vfx_particle_release_grace_seconds
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(func() -> void:
		if Utility.is_object_valid(particles):
			particles.emitting = false
		node_pool.release(particles))
