extends Node3D
## Engancha un arma (PackedScene) al hueso de la mano derecha del Skeleton3D del personaje.

@export var weapon_scene: PackedScene
@export var bone_names: Array[String] = [
	"mixamorig:RightHand",
	"RightHand",
	"mixamorig_RightHand",
]
## Ajuste fino en la mano (después de escalar el GLB en rifle.tscn).
@export var weapon_position := Vector3(0.0, 0.02, 0.04)
@export var weapon_rotation_degrees := Vector3(-90.0, 0.0, 0.0)
@export var weapon_scale := Vector3(1.0, 1.0, 1.0)


func _ready() -> void:
	if weapon_scene == null:
		push_warning("WeaponAttach: asigná weapon_scene (scenes/weapons/rifle.tscn)")
		return

	var skeleton := _find_skeleton(_get_character_root())
	if skeleton == null:
		push_warning("WeaponAttach: no se encontró Skeleton3D en el personaje")
		return

	var bone := _resolve_bone(skeleton)
	if bone.is_empty():
		push_warning("WeaponAttach: hueso de mano no encontrado. Huesos: ", skeleton.get_bone_names())
		return

	var attach := BoneAttachment3D.new()
	attach.name = "WeaponAttachment"
	attach.bone_name = bone
	skeleton.add_child(attach)

	var weapon := weapon_scene.instantiate()
	attach.add_child(weapon)
	weapon.position = weapon_position
	weapon.rotation_degrees = weapon_rotation_degrees
	weapon.scale = weapon_scale


func _get_character_root() -> Node:
	var node: Node = get_parent()
	while node:
		if node is CharacterBody3D:
			return node
		node = node.get_parent()
	return get_parent()


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null


func _resolve_bone(skeleton: Skeleton3D) -> String:
	for bone_name in bone_names:
		if skeleton.find_bone(bone_name) >= 0:
			return bone_name
	for i in skeleton.get_bone_count():
		var skel_bone := skeleton.get_bone_name(i)
		if skel_bone.contains("RightHand") or skel_bone.contains("right_hand"):
			return skel_bone
	return ""
