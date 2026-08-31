extends SceneTree
## ¿Las anims Mixamo traen los dedos cerrados o las manos abiertas?
## godot --headless --path MafiaGardenGodot -s res://scripts/editor/probe_finger_tracks.gd

const CHAR_SCENE := "res://soldado_anim.tscn"


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var packed: PackedScene = load(CHAR_SCENE) as PackedScene
	var root_node: Node3D = packed.instantiate() as Node3D
	root.add_child(root_node)
	var player := _find_player(root_node)
	var skel := _find_skel(root_node)
	if player == null or skel == null:
		print("[Fingers] FAIL player=%s skel=%s" % [player, skel])
		quit(1)
		return

	print("[Fingers] anims=%s" % str(player.get_animation_list()))

	# Huesos de dedos: si la anim los mueve, hay agarre; si no, mano en reposo.
	var finger_bones: Array[String] = []
	for i in skel.get_bone_count():
		var n := skel.get_bone_name(i)
		var low := n.to_lower()
		if "hand" in low and ("index" in low or "middle" in low or "thumb" in low or "ring" in low or "pinky" in low):
			finger_bones.append(n)
	print("[Fingers] huesos de dedos en el skeleton = %d" % finger_bones.size())

	for anim_name in player.get_animation_list():
		var anim := player.get_animation(anim_name)
		if anim == null:
			continue
		var finger_tracks := 0
		var moving := 0
		for t in range(anim.get_track_count()):
			if anim.track_get_type(t) != Animation.TYPE_ROTATION_3D:
				continue
			var path := str(anim.track_get_path(t))
			var is_finger := false
			for fb in finger_bones:
				if path.ends_with(":" + fb):
					is_finger = true
					break
			if not is_finger:
				continue
			finger_tracks += 1
			# ¿varía la rotación a lo largo del clip?
			var kc := anim.track_get_key_count(t)
			if kc >= 2:
				var q0: Quaternion = anim.track_get_key_value(t, 0)
				var qn: Quaternion = anim.track_get_key_value(t, kc - 1)
				if absf(q0.dot(qn)) < 0.9995:
					moving += 1
		print(
			"[Fingers] %-34s len=%.2f finger_tracks=%d con_movimiento=%d"
			% [anim_name, anim.length, finger_tracks, moving]
		)

	# Curl real: ángulo entre el hueso de dedo y su reposo, en el frame 0.
	for anim_name in player.get_animation_list():
		if not ("Idle" in anim_name or "Firing" in anim_name):
			continue
		player.play(anim_name)
		player.seek(0.0, true)
		await process_frame
		var total := 0.0
		var n := 0
		for fb in finger_bones:
			var idx := skel.find_bone(fb)
			if idx < 0:
				continue
			var rest_q := skel.get_bone_rest(idx).basis.get_rotation_quaternion()
			var pose_q := skel.get_bone_pose_rotation(idx)
			total += rad_to_deg(rest_q.angle_to(pose_q))
			n += 1
		print(
			"[Fingers] %-34s curl_medio_vs_reposo=%.1f deg (n=%d)"
			% [anim_name, total / maxf(1.0, float(n)), n]
		)
	quit(0)


func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for c in node.get_children():
		var f := _find_player(c)
		if f:
			return f
	return null


func _find_skel(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for c in node.get_children():
		var f := _find_skel(c)
		if f:
			return f
	return null
