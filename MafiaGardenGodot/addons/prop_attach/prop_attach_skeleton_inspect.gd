extends RefCounted
## Inspección genérica de Skeleton3D (Mixamo y variantes).

const HAND_HINTS := {
	"right": ["righthand", "hand.r", "hand_r", "r_hand"],
	"left": ["lefthand", "hand.l", "hand_l", "l_hand"],
}
const FOREARM_HINTS := {
	"right": ["rightforearm", "forearm.r", "lowerarm.r", "r_forearm"],
	"left": ["leftforearm", "forearm.l", "lowerarm.l", "l_forearm"],
}
const UPPERARM_HINTS := {
	"right": ["rightarm", "upperarm.r", "arm.r", "r_arm"],
	"left": ["leftarm", "upperarm.l", "arm.l", "l_arm"],
}


static func inspect(skeleton: Skeleton3D) -> Dictionary:
	if skeleton == null:
		return {"error": "skeleton_null", "bones": []}
	var bones: Array = []
	for i in skeleton.get_bone_count():
		bones.append({
			"index": i,
			"name": skeleton.get_bone_name(i),
			"parent": skeleton.get_bone_parent(i),
		})
	return {
		"bone_count": skeleton.get_bone_count(),
		"bones": bones,
		"hand_bones": {
			"right": resolve_bone(skeleton, HAND_HINTS["right"], ["mixamorig:RightHand", "RightHand"]),
			"left": resolve_bone(skeleton, HAND_HINTS["left"], ["mixamorig:LeftHand", "LeftHand"]),
		},
		"forearm_bones": {
			"right": resolve_bone(skeleton, FOREARM_HINTS["right"], ["mixamorig:RightForeArm", "RightForeArm"]),
			"left": resolve_bone(skeleton, FOREARM_HINTS["left"], ["mixamorig:LeftForeArm", "LeftForeArm"]),
		},
		"upperarm_bones": {
			"right": resolve_bone(skeleton, UPPERARM_HINTS["right"], ["mixamorig:RightArm", "RightArm"]),
			"left": resolve_bone(skeleton, UPPERARM_HINTS["left"], ["mixamorig:LeftArm", "LeftArm"]),
		},
		"mixamo_like": _looks_mixamo(skeleton),
	}


static func resolve_bone(skeleton: Skeleton3D, suffixes: Array, prefers: Array = []) -> String:
	if skeleton == null:
		return ""
	var prefer_list: Array = prefers.duplicate()
	# Variantes colon/underscore de cada preferido.
	for prefer in prefers:
		var p := String(prefer)
		if ":" in p:
			prefer_list.append(p.replace(":", "_"))
		elif "_" in p and "mixamorig" in p.to_lower():
			prefer_list.append(p.replace("_", ":"))
	for prefer in prefer_list:
		if skeleton.find_bone(String(prefer)) >= 0:
			return String(prefer)
	# Solo ends_with del hint normalizado (evita hand.r ⊂ LeftHandRing).
	for i in skeleton.get_bone_count():
		var name := skeleton.get_bone_name(i)
		var lower := name.to_lower().replace(":", "").replace("_", "").replace(".", "")
		for hint in suffixes:
			var h := String(hint).to_lower().replace("_", "").replace(".", "")
			if h.is_empty():
				continue
			if lower.ends_with(h):
				return name
	return ""


static func _looks_mixamo(skeleton: Skeleton3D) -> bool:
	for i in mini(skeleton.get_bone_count(), 40):
		var n := skeleton.get_bone_name(i).to_lower()
		if "mixamorig" in n:
			return true
	return false


static func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := find_skeleton(child)
		if found:
			return found
	return null


static func find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := find_animation_player(child)
		if found:
			return found
	return null
