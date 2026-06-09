extends Node3D


func setup(from_enemy: bool) -> void:
	var particles := get_node_or_null("Particles") as GPUParticles3D
	if particles == null:
		return
	var mat := particles.process_material as ParticleProcessMaterial
	if mat:
		mat.color = Color(1.0, 0.35, 0.25) if from_enemy else Color(1.0, 0.75, 0.2)
	particles.emitting = true
	get_tree().create_timer(0.35).timeout.connect(queue_free)
