extends Node3D


func _ready() -> void:
	var light := get_node_or_null("Flash") as OmniLight3D
	if light:
		var tween := create_tween()
		tween.tween_property(light, "light_energy", 0.0, 0.08)
	get_tree().create_timer(0.1).timeout.connect(queue_free)
