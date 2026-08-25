extends Node3D
## Sistema unico de arma: BoneAttachment + offset fijo + IK opcional mano izq.
## Modo spawn: crea BoneAttachment e instancia rifle.tscn (enemigo).
## Modo embedded: rifle ya en la escena del personaje (soldado).

signal weapon_attached(weapon_root: Node3D)

enum AttachMode { SPAWN, EMBEDDED }

@export_group("Arma")
@export var attach_mode: AttachMode = AttachMode.SPAWN
@export var weapon_scene: PackedScene
@export var weapon_position := Vector3(0.0, 0.0, 0.0)
@export var weapon_rotation_degrees := Vector3(-90.0, 0.0, 0.0)
@export var weapon_scale := Vector3(1.0, 1.0, 1.0)

@export var bone_names: Array[String] = [
	"mixamorig:RightHand",
	"mixamorig_RightHand",
	"RightHand",
]
@export var left_hand_bone_names: Array[String] = [
	"mixamorig:LeftHand",
	"mixamorig_LeftHand",
	"LeftHand",
]

@export_group("Mano izquierda (IK)")
@export var left_hand_ik := false
@export_range(0.0, 1.0, 0.05) var idle_ik_influence := 0.85
@export_range(0.0, 1.0, 0.05) var firing_ik_influence := 1.0
@export_range(0.0, 1.0, 0.05) var walk_ik_influence := 0.85
@export var pole_distance := 0.38
@export var pole_height := 0.08

@export_group("Visibilidad")
@export var hide_when_no_rifle_pose := true

@export_group("Encaje entre manos")
## Cada frame: Grip -> mano derecha, cañón alineado con la linea entre manos,
## Foregrip corrido sobre el guardamanos hasta la mano izquierda.
@export var fit_between_hands := true
## Corrimiento del Grip desde el hueso de la muñeca hacia la palma.
@export var grip_palm_offset := Vector3(0.0, 0.0, 0.0)
## Recorrido util del guardamanos medido sobre la malla del AK (metros desde Grip).
@export var handguard_min_m := 0.28
@export var handguard_max_m := 0.42

@export_group("Auto-alineacion (legacy, solo si las anims traen dedos)")
@export var auto_align_to_hands := false
@export_range(0.0, 1.0, 0.05) var idle_forearm_weight := 0.65
@export_range(0.0, 1.0, 0.05) var firing_hands_weight := 0.85

var _weapon_root: Node3D
var _skeleton: Skeleton3D
var _bone_attachment: BoneAttachment3D
var _foregrip: Node3D
var _grip: Node3D
var _muzzle: Node3D
var _anim_player: AnimationPlayer
var _ik: SkeletonModifier3D
var _pole: Node3D
var _right_bone := ""
var _left_bone := ""
var _right_forearm_bone := ""
var _finger_applier: Node


func _ready() -> void:
	call_deferred("_setup")


func _setup() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	match attach_mode:
		AttachMode.SPAWN:
			_setup_spawn()
		AttachMode.EMBEDDED:
			_setup_embedded()
	if _weapon_root == null or _skeleton == null:
		return
	_apply_calib_once()
	if left_hand_ik:
		_setup_left_hand_ik()
	_setup_finger_pose()
	weapon_attached.emit(_weapon_root)


func _process(_delta: float) -> void:
	if _weapon_root == null:
		return
	_update_visibility()
	if fit_between_hands:
		_fit_between_hands()
	elif auto_align_to_hands:
		_apply_auto_align()
	if _ik != null:
		_update_pole()
		_ik.influence = _ik_influence_for_anim(_current_anim())


func get_weapon_root() -> Node3D:
	return _weapon_root


func get_muzzle_global_position() -> Vector3:
	if _muzzle:
		return _muzzle.global_position
	if _weapon_root:
		return _weapon_root.global_position
	return global_position


# --- Setup -------------------------------------------------------------------

func _setup_spawn() -> void:
	if weapon_scene == null:
		push_warning("WeaponAttach: asigna weapon_scene")
		return
	var model_root := get_parent()
	if model_root == null:
		return
	_skeleton = _find_skeleton(model_root)
	if _skeleton == null:
		push_warning("WeaponAttach: no Skeleton3D bajo %s" % model_root.get_path())
		return
	_right_bone = _resolve_bone(_skeleton, bone_names, "righthand")
	_left_bone = _resolve_bone(_skeleton, left_hand_bone_names, "lefthand")
	if _right_bone.is_empty():
		return
	_bone_attachment = BoneAttachment3D.new()
	_bone_attachment.name = "WeaponAttachment"
	_bone_attachment.bone_name = _right_bone
	_bone_attachment.bone_idx = _skeleton.find_bone(_right_bone)
	_skeleton.add_child(_bone_attachment)
	_weapon_root = weapon_scene.instantiate() as Node3D
	_bone_attachment.add_child(_weapon_root)
	_weapon_root.scale = weapon_scale
	_cache_weapon_nodes()
	_anim_player = AnimHelper.find_animation_player(_owner_character())


func _setup_embedded() -> void:
	_skeleton = _find_skeleton(self)
	_weapon_root = find_child("Rifle", true, false) as Node3D
	_bone_attachment = _find_bone_attachment()
	if _skeleton:
		_right_bone = _resolve_bone(_skeleton, bone_names, "righthand")
		_left_bone = _resolve_bone(_skeleton, left_hand_bone_names, "lefthand")
		_right_forearm_bone = _find_bone_suffix(_skeleton, "rightforearm")
	_cache_weapon_nodes()
	_anim_player = AnimHelper.find_animation_player(self)
	if _skeleton and _skeleton.has_method("set_modifier_callback_mode_process"):
		_skeleton.set("modifier_callback_mode_process", 1)


func _apply_calib_once() -> void:
	var store := get_node_or_null("/root/WeaponCalibStore")
	if store == null or not store.has_saved():
		_weapon_root.position = weapon_position
		_weapon_root.rotation_degrees = weapon_rotation_degrees
		return
	store.apply_to_soldado(_embed_root())


func _embed_root() -> Node3D:
	if attach_mode == AttachMode.EMBEDDED:
		return self
	var model := get_parent()
	return model if model else self


func _cache_weapon_nodes() -> void:
	if _weapon_root == null:
		return
	_grip = _weapon_root.find_child("Grip", true, false) as Node3D
	_foregrip = _weapon_root.find_child("Foregrip", true, false) as Node3D
	_muzzle = _weapon_root.find_child("Muzzle", true, false) as Node3D


func _setup_left_hand_ik() -> void:
	if _skeleton == null or _foregrip == null:
		push_warning("WeaponAttach: IK requiere Skeleton3D + Foregrip")
		return
	if not ClassDB.class_exists("TwoBoneIK3D"):
		return
	var root_bone := _resolve_bone(_skeleton, ["mixamorig_LeftArm", "mixamorig_LeftArm"], "leftarm")
	var mid_bone := _resolve_bone(_skeleton, ["mixamorig_LeftForeArm", "mixamorig_LeftForeArm"], "leftforearm")
	var end_bone := _left_bone
	if root_bone.is_empty() or end_bone.is_empty():
		return
	_pole = _skeleton.get_node_or_null("LeftElbowPole") as Node3D
	if _pole == null:
		_pole = Node3D.new()
		_pole.name = "LeftElbowPole"
		_skeleton.add_child(_pole)
	_ik = _skeleton.get_node_or_null("LeftHandIK") as SkeletonModifier3D
	if _ik == null:
		_ik = ClassDB.instantiate("TwoBoneIK3D") as SkeletonModifier3D
		_ik.name = "LeftHandIK"
		_skeleton.add_child(_ik)
	_ik.call("set_setting_count", 1)
	_ik_set_bone(0, "root", root_bone)
	_ik_set_bone(0, "middle", mid_bone if not mid_bone.is_empty() else _right_forearm_bone)
	_ik_set_bone(0, "end", end_bone)
	_ik.call("set_target_node", 0, _skeleton.get_path_to(_foregrip))
	_ik.call("set_pole_node", 0, _skeleton.get_path_to(_pole))
	_ik.set("active", true)
	_ik.influence = idle_ik_influence
	_update_pole()


func _ik_set_bone(idx: int, kind: String, bone_name: String) -> void:
	if bone_name.is_empty():
		return
	var bone_idx := _skeleton.find_bone(bone_name)
	if bone_idx >= 0:
		_ik.call("set_%s_bone" % kind, idx, bone_idx)
	else:
		_ik.call("set_%s_bone_name" % kind, idx, bone_name)


func _setup_finger_pose() -> void:
	if _skeleton == null:
		return
	var store := get_node_or_null("/root/WeaponCalibStore")
	if store == null or not store.has_finger_pose():
		return
	var applier_script := preload("res://scripts/finger_pose_applier.gd")
	_finger_applier = _skeleton.get_node_or_null("FingerPoseApplier")
	if _finger_applier == null:
		_finger_applier = applier_script.new()
		_finger_applier.name = "FingerPoseApplier"
		_skeleton.add_child(_finger_applier)
	_finger_applier.setup_skeleton(_skeleton)
	_finger_applier.set_poses(store.finger_poses, true)


# --- Runtime -----------------------------------------------------------------

func _update_pole() -> void:
	if _pole == null or _skeleton == null or _left_bone.is_empty() or _foregrip == null:
		return
	var elbow := _bone_world(_left_bone)
	var target := _foregrip.global_position
	var mid := (elbow + target) * 0.5 + Vector3.UP * pole_height
	var side := (target - elbow).cross(Vector3.UP)
	if side.length_squared() < 0.0001:
		side = Vector3.RIGHT
	_pole.global_position = mid + side.normalized() * pole_distance


func _update_visibility() -> void:
	if not hide_when_no_rifle_pose:
		_weapon_root.visible = true
		return
	var anim := _current_anim().to_lower()
	var show := anim.is_empty() or "idle" in anim or "fire" in anim or "firing" in anim or "rifle" in anim or "firigin" in anim
	if "walk" in anim or "run" in anim or "jog" in anim:
		show = false
	_weapon_root.visible = show


func _ik_influence_for_anim(anim: String) -> float:
	var lower := anim.to_lower()
	if "fire" in lower or "firing" in lower or "rifle" in lower or "firigin" in lower:
		return firing_ik_influence
	if "walk" in lower or "run" in lower or "jog" in lower:
		return walk_ik_influence
	return idle_ik_influence


# --- Encaje entre manos ------------------------------------------------------

## El arma se adapta a las manos, no las manos al arma: con animaciones Mixamo
## sin pose de dedos esto es lo unico que garantiza que quede entre las dos.
func _fit_between_hands() -> void:
	if _bone_attachment == null or _grip == null or _muzzle == null:
		return
	if _right_bone.is_empty() or _left_bone.is_empty():
		return
	var right_w := _bone_world(_right_bone)
	var left_w := _bone_world(_left_bone)
	var hands := left_w - right_w
	var hands_dist := hands.length()
	if hands_dist < 0.05:
		return
	var dir := hands / hands_dist

	# Rotacion: cañon local -> linea entre manos, con el cargador hacia abajo.
	var barrel_local := (_muzzle.position - _grip.position)
	if barrel_local.length_squared() < 0.0001:
		return
	barrel_local = barrel_local.normalized()
	var up_world := Vector3.UP
	if absf(dir.dot(up_world)) > 0.92:
		up_world = Vector3.RIGHT
	var mesh_up := Vector3(0.0, 0.0, -1.0)
	if absf(barrel_local.dot(mesh_up)) > 0.92:
		mesh_up = Vector3.RIGHT
	var attach_basis := _bone_attachment.global_transform.basis
	var target := Basis.looking_at(-dir, up_world)
	var mesh_fix := Basis.looking_at(-barrel_local, mesh_up)
	_weapon_root.basis = attach_basis.inverse() * target * mesh_fix.inverse()

	# Posicion: Grip exactamente sobre la mano derecha.
	var attach_inv := _bone_attachment.global_transform.affine_inverse()
	var want_grip_w := right_w + _weapon_root.global_transform.basis * grip_palm_offset
	_weapon_root.position += attach_inv * want_grip_w - attach_inv * _grip.global_position

	# Foregrip sobre el guardamanos, a la distancia real entre manos.
	if _foregrip:
		var along := clampf(hands_dist, handguard_min_m, handguard_max_m)
		_foregrip.position = barrel_local * along


# --- Auto-align legacy (enemigo/chica) ---------------------------------------

func _apply_auto_align() -> void:
	if _weapon_root == null or _bone_attachment == null or _skeleton == null:
		return
	if _right_bone.is_empty() or _left_bone.is_empty():
		return
	var right_w := _bone_world(_right_bone)
	var left_w := _bone_world(_left_bone)
	var hands := left_w - right_w
	if hands.length_squared() < 0.0025:
		return
	var hands_dir := hands.normalized()
	var forearm := _forearm_dir(right_w)
	var anim := _current_anim()
	var barrel_dir := hands_dir
	if forearm.length_squared() > 0.0001:
		var w := firing_hands_weight if _is_fire_anim(anim) else idle_forearm_weight
		barrel_dir = (forearm.lerp(hands_dir, 1.0 - w)).normalized()
	var up := Vector3.UP
	if absf(barrel_dir.dot(up)) > 0.92:
		up = Vector3.RIGHT
	var barrel_local := _barrel_local()
	if barrel_local.length_squared() < 0.0001:
		barrel_local = Vector3.FORWARD
	var target_world := Basis.looking_at(-barrel_dir, up)
	var mesh_fix := Basis.looking_at(-barrel_local.normalized(), Vector3.UP)
	var attach_basis := _bone_attachment.global_transform.basis
	_weapon_root.basis = attach_basis.inverse() * target_world * mesh_fix.inverse()
	_weapon_root.position = weapon_position


func _barrel_local() -> Vector3:
	if _grip and _muzzle:
		return _muzzle.position - _grip.position
	return Vector3(0.0, -0.565, 0.07)


func _forearm_dir(hand_w: Vector3) -> Vector3:
	if _right_forearm_bone.is_empty():
		_right_forearm_bone = _find_bone_suffix(_skeleton, "rightforearm")
	if _right_forearm_bone.is_empty():
		return Vector3.ZERO
	var elbow := _bone_world(_right_forearm_bone)
	var d := hand_w - elbow
	return d.normalized() if d.length_squared() > 0.0001 else Vector3.ZERO


# --- Helpers -----------------------------------------------------------------

func _owner_character() -> Node:
	if attach_mode == AttachMode.EMBEDDED:
		return self
	var model := get_parent()
	return model.get_parent() if model and model.get_parent() else self


func _current_anim() -> String:
	if _anim_player:
		return String(_anim_player.current_animation)
	var ch := _owner_character()
	if ch:
		var p := AnimHelper.find_animation_player(ch)
		if p:
			return String(p.current_animation)
	return ""


func _is_fire_anim(anim: String) -> bool:
	var lower := anim.to_lower()
	return "fire" in lower or "firing" in lower or "rifle" in lower or "firigin" in lower


func _bone_world(bone_name: String) -> Vector3:
	var idx := _skeleton.find_bone(bone_name)
	if idx < 0:
		return Vector3.ZERO
	return (_skeleton.global_transform * _skeleton.get_bone_global_pose(idx)).origin


func _find_bone_attachment() -> BoneAttachment3D:
	if _weapon_root == null:
		return null
	var p := _weapon_root.get_parent()
	while p:
		if p is BoneAttachment3D:
			return p as BoneAttachment3D
		p = p.get_parent()
	return null


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var f := _find_skeleton(child)
		if f:
			return f
	return null


func _resolve_bone(skeleton: Skeleton3D, names: Array[String], suffix: String) -> String:
	for n in names:
		if skeleton.find_bone(n) >= 0:
			return n
	for i in skeleton.get_bone_count():
		var bn := skeleton.get_bone_name(i)
		if bn.to_lower().ends_with(suffix):
			return bn
	return ""


func _find_bone_suffix(skeleton: Skeleton3D, suffix: String) -> String:
	for i in skeleton.get_bone_count():
		var bn := skeleton.get_bone_name(i)
		if bn.to_lower().ends_with(suffix):
			return bn
	return ""
