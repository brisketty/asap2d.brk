class_name AmbientParticleLayer
extends CanvasLayer
## A screen-space looping ambient particle emitter (dust motes, snow, embers).
## `configure()` swaps the process material and toggles emission; a null / wrong
## material stops it cleanly (defensive defaulting - no crash, no stray loop).

@export_group("Nodes", "node_")
@export var node_particles: GPUParticles2D


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/ambient_particle_layer.tscn") as PackedScene


func configure(p_particle_material: Resource) -> void:
	if not Utility.is_object_valid(node_particles):
		return
	var process_material := p_particle_material as ParticleProcessMaterial
	if Utility.is_object_valid(process_material):
		node_particles.process_material = process_material
		node_particles.emitting = true
		return
	node_particles.emitting = false
