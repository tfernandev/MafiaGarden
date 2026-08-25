extends RefCounted
## Utilidades para capturar y aplicar poses de dedos (Mixamo).

const SIDES := ["Left", "Right"]
const FINGERS := ["Thumb", "Index", "Middle", "Ring", "Pinky"]
const JOINTS := [1, 2, 3, 4]

const FINGER_LABELS_ES := {
	"Thumb": "pulgar",
	"Index": "índice",
	"Middle": "medio",
	"Ring": "anular",
	"Pinky": "meñique",
}

const FINGER_COLORS := {
	"Thumb": Color(1.0, 0.85, 0.2),
	"Index": Color(1.0, 0.5, 0.15),
	"Middle": Color(1.0, 0.25, 0.25),
	"Ring": Color(0.85, 0.35, 1.0),
	"Pinky": Color(0.45, 0.65, 1.0),
}

const RIGHT_HAND_BONE := "mixamorig:RightHand"
const LEFT_HAND_BONE := "mixamorig:LeftHand"


static func all_bone_names() -> Array[String]:
	var names: Array[String] = []
	for side in SIDES:
		for finger in FINGERS:
			for joint in JOINTS:
				names.append(_bone_name(side, finger, joint))
	return names


static func bone_label(bone_name: String) -> String:
	for side in SIDES:
		for finger in FINGERS:
			for joint in JOINTS:
				if bone_name == _bone_name(side, finger, joint):
					var side_es := "Der." if side == "Right" else "Izq."
					return "%s %s %d" % [side_es, FINGER_LABELS_ES[finger], joint]
	return bone_name


static func capture_from_skeleton(skeleton: Skeleton3D) -> Dictionary:
	var out: Dictionary = {}
	for bone_name in all_bone_names():
		var idx := _find_bone(skeleton, bone_name)
		if idx >= 0:
			out[bone_name] = skeleton.get_bone_pose_rotation(idx)
	return out


static func apply_to_skeleton(skeleton: Skeleton3D, poses: Dictionary) -> void:
	for key in poses.keys():
		var bone_name: String = key as String
		var idx := _find_bone(skeleton, bone_name)
		if idx >= 0:
			skeleton.set_bone_pose_rotation(idx, poses[bone_name] as Quaternion)


static func apply_hand_offsets(skeleton: Skeleton3D, offsets: Dictionary) -> void:
	for key in offsets.keys():
		var bone_name: String = key as String
		var idx := _find_bone(skeleton, bone_name)
		if idx < 0:
			continue
		var offset: Vector3 = offsets[bone_name]
		var pos := skeleton.get_bone_pose_position(idx) + offset
		skeleton.set_bone_pose_position(idx, pos)


static func tip_bone_name(side: String, finger: String) -> String:
	return _bone_name(side, finger, 4)


static func proximal_bone_name(side: String, finger: String) -> String:
	return _bone_name(side, finger, 1)


static func finger_color(finger: String) -> Color:
	return FINGER_COLORS.get(finger, Color.WHITE)


static func find_bone_index(skeleton: Skeleton3D, bone_name: String) -> int:
	return _find_bone(skeleton, bone_name)


static func parse_finger_chain(bone_name: String) -> Array:
	for side in SIDES:
		for finger in FINGERS:
			for joint in JOINTS:
				if bone_name == _bone_name(side, finger, joint):
					return [side, finger]
	return []


static func chain_bone_names(side: String, finger: String) -> Array[String]:
	var names: Array[String] = []
	for joint in [1, 2, 3]:
		names.append(_bone_name(side, finger, joint))
	return names




static func _bone_name(side: String, finger: String, joint: int) -> String:
	return "mixamorig:%sHand%s%d" % [side, finger, joint]


static func _find_bone(skeleton: Skeleton3D, bone_name: String) -> int:
	var idx := skeleton.find_bone(bone_name)
	if idx >= 0:
		return idx
	return skeleton.find_bone(bone_name.replace(":", "_"))
