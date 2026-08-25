extends SkeletonModifier3D
## Aplica pose de dedos y offset de muñecas DESPUÉS de la animación (sin acumular).

const FingerPoseUtilScript := preload("res://scripts/finger_pose_util.gd")

var _poses: Dictionary = {}
var _hand_offsets: Dictionary = {}
var _active := false


func setup_skeleton(skeleton: Skeleton3D) -> void:
	if skeleton == null:
		return
	if get_parent() != skeleton:
		if get_parent():
			get_parent().remove_child(self)
		skeleton.add_child(self)
	# active = false evita modificar hasta que haya poses/offsets.
	active = _active


func set_poses(poses: Dictionary, poses_active: bool) -> void:
	_poses = poses.duplicate() if poses_active else {}
	_recalc_active()


func set_hand_offsets(offsets: Dictionary) -> void:
	_hand_offsets = offsets.duplicate()
	_recalc_active()


func _recalc_active() -> void:
	_active = not _poses.is_empty() or not _hand_offsets.is_empty()
	active = _active


func has_manual_pose() -> bool:
	return _active


func get_poses() -> Dictionary:
	return _poses.duplicate()


func get_hand_offsets() -> Dictionary:
	return _hand_offsets.duplicate()


func _process_modification() -> void:
	if not _active:
		return
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	if not _poses.is_empty():
		FingerPoseUtilScript.apply_to_skeleton(skeleton, _poses)
	if not _hand_offsets.is_empty():
		FingerPoseUtilScript.apply_hand_offsets(skeleton, _hand_offsets)
