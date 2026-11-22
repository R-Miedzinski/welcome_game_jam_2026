class_name FokaEat
extends Node3D

@onready var particles: GPUParticles3D = $GPUParticles3D

func emit() -> void:
	if not is_instance_valid(particles):
		return
		
	particles.emitting = true