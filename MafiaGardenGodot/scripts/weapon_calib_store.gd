extends Node
## Guarda la calibración manual del rifle y pose de dedos (taller debug).

const SAVE_PATH := "user://weapon_calib.cfg"
const BAKED_PATH := "res://weapon_calib_baked.cfg"
const FingerPoseUtilScript := preload("res://scripts/finger_pose_util.gd")

var use_manual_calib := false
var rifle_position := Vector3.ZERO
var rifle_rotation_degrees := Vector3(-90.0, 0.0, 0.0)
var foregrip_local := Vector3(0.0, -0.33, 0.05)
var muzzle_local := Vector3(0.0, -0.565, 0.07)
var hold_slide_m := 0.0
var use_finger_pose := false
var finger_poses: Dictionary = {}
var right_hand_offset := Vector3.ZERO
var left_hand_offset := Vector3.ZERO


func _ready() -> void:
	load_saved()


func has_saved() -> bool:
	return use_manual_calib


func has_finger_pose() -> bool:
	return use_finger_pose and not finger_poses.is_empty()


func load_saved() -> void:
	var path := SAVE_PATH if FileAccess.file_exists(SAVE_PATH) else BAKED_PATH
	if not FileAccess.file_exists(path):
		return
	_load_from_path(path)


func _load_from_path(path: String) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	use_manual_calib = cfg.get_value("calib", "use_manual", false)
	rifle_position = Vector3(
		cfg.get_value("calib", "rifle_px", rifle_position.x),
		cfg.get_value("calib", "rifle_py", rifle_position.y),
		cfg.get_value("calib", "rifle_pz", rifle_position.z)
	)
	rifle_rotation_degrees = Vector3(
		cfg.get_value("calib", "rifle_rx", rifle_rotation_degrees.x),
		cfg.get_value("calib", "rifle_ry", rifle_rotation_degrees.y),
		cfg.get_value("calib", "rifle_rz", rifle_rotation_degrees.z)
	)
	foregrip_local = Vector3(
		cfg.get_value("calib", "foregrip_x", foregrip_local.x),
		cfg.get_value("calib", "foregrip_y", foregrip_local.y),
		cfg.get_value("calib", "foregrip_z", foregrip_local.z)
	)
	muzzle_local = Vector3(
		cfg.get_value("calib", "muzzle_x", muzzle_local.x),
		cfg.get_value("calib", "muzzle_y", muzzle_local.y),
		cfg.get_value("calib", "muzzle_z", muzzle_local.z)
	)
	hold_slide_m = cfg.get_value("calib", "hold_slide_m", 0.0)
	use_finger_pose = cfg.get_value("fingers", "use_manual", false)
	finger_poses = _load_finger_poses_from_cfg(cfg)
	right_hand_offset = Vector3(
		cfg.get_value("calib", "hand_rx", right_hand_offset.x),
		cfg.get_value("calib", "hand_ry", right_hand_offset.y),
		cfg.get_value("calib", "hand_rz", right_hand_offset.z)
	)
	left_hand_offset = Vector3(
		cfg.get_value("calib", "hand_lx", left_hand_offset.x),
		cfg.get_value("calib", "hand_ly", left_hand_offset.y),
		cfg.get_value("calib", "hand_lz", left_hand_offset.z)
	)


func save_current(
	rifle_pos: Vector3,
	rifle_rot_deg: Vector3,
	foregrip: Vector3,
	muzzle: Vector3,
	finger_pose: Dictionary = {},
	hand_offsets: Dictionary = {},
	hold_slide: float = 0.0
) -> void:
	use_manual_calib = true
	rifle_position = rifle_pos
	rifle_rotation_degrees = rifle_rot_deg
	foregrip_local = foregrip
	muzzle_local = muzzle
	hold_slide_m = hold_slide
	use_finger_pose = not finger_pose.is_empty()
	finger_poses = finger_pose.duplicate() if use_finger_pose else {}
	right_hand_offset = hand_offsets.get(FingerPoseUtilScript.RIGHT_HAND_BONE, Vector3.ZERO)
	left_hand_offset = hand_offsets.get(FingerPoseUtilScript.LEFT_HAND_BONE, Vector3.ZERO)
	var cfg := ConfigFile.new()
	cfg.set_value("calib", "use_manual", true)
	cfg.set_value("calib", "rifle_px", rifle_pos.x)
	cfg.set_value("calib", "rifle_py", rifle_pos.y)
	cfg.set_value("calib", "rifle_pz", rifle_pos.z)
	cfg.set_value("calib", "rifle_rx", rifle_rot_deg.x)
	cfg.set_value("calib", "rifle_ry", rifle_rot_deg.y)
	cfg.set_value("calib", "rifle_rz", rifle_rot_deg.z)
	cfg.set_value("calib", "foregrip_x", foregrip.x)
	cfg.set_value("calib", "foregrip_y", foregrip.y)
	cfg.set_value("calib", "foregrip_z", foregrip.z)
	cfg.set_value("calib", "muzzle_x", muzzle.x)
	cfg.set_value("calib", "muzzle_y", muzzle.y)
	cfg.set_value("calib", "muzzle_z", muzzle.z)
	cfg.set_value("calib", "hold_slide_m", hold_slide_m)
	cfg.set_value("calib", "hand_rx", right_hand_offset.x)
	cfg.set_value("calib", "hand_ry", right_hand_offset.y)
	cfg.set_value("calib", "hand_rz", right_hand_offset.z)
	cfg.set_value("calib", "hand_lx", left_hand_offset.x)
	cfg.set_value("calib", "hand_ly", left_hand_offset.y)
	cfg.set_value("calib", "hand_lz", left_hand_offset.z)
	_save_finger_poses_to_cfg(cfg, finger_poses)
	cfg.save(SAVE_PATH)
	if FileAccess.file_exists(BAKED_PATH) or OS.has_feature("editor"):
		cfg.save(BAKED_PATH)


func clear_saved() -> void:
	use_manual_calib = false
	use_finger_pose = false
	finger_poses = {}
	right_hand_offset = Vector3.ZERO
	left_hand_offset = Vector3.ZERO
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func apply_to_soldado(soldado_root: Node3D) -> void:
	if not use_manual_calib:
		return
	var rifle := soldado_root.find_child("Rifle", true, false) as Node3D
	if rifle:
		rifle.position = rifle_position
		rifle.rotation_degrees = rifle_rotation_degrees
		if hold_slide_m > 0.0:
			rifle.set_meta("hold_slide_m", hold_slide_m)
	var foregrip := soldado_root.find_child("Foregrip", true, false) as Node3D
	if foregrip:
		foregrip.position = foregrip_local
	var muzzle := soldado_root.find_child("Muzzle", true, false) as Node3D
	if muzzle:
		muzzle.position = muzzle_local


func _load_finger_poses_from_cfg(cfg: ConfigFile) -> Dictionary:
	var out: Dictionary = {}
	if not cfg.has_section("fingers"):
		return out
	for bone_name in FingerPoseUtilScript.all_bone_names():
		var prefix: String = bone_name.replace(":", "_")
		if not cfg.has_section_key("fingers", "%s_w" % prefix):
			continue
		out[bone_name] = Quaternion(
			cfg.get_value("fingers", "%s_x" % prefix, 0.0),
			cfg.get_value("fingers", "%s_y" % prefix, 0.0),
			cfg.get_value("fingers", "%s_z" % prefix, 0.0),
			cfg.get_value("fingers", "%s_w" % prefix, 1.0)
		)
	return out


func _save_finger_poses_to_cfg(cfg: ConfigFile, poses: Dictionary) -> void:
	cfg.set_value("fingers", "use_manual", not poses.is_empty())
	for key in poses.keys():
		var bone_name: String = key as String
		var prefix: String = bone_name.replace(":", "_")
		var q := poses[bone_name] as Quaternion
		cfg.set_value("fingers", "%s_x" % prefix, q.x)
		cfg.set_value("fingers", "%s_y" % prefix, q.y)
		cfg.set_value("fingers", "%s_z" % prefix, q.z)
		cfg.set_value("fingers", "%s_w" % prefix, q.w)
