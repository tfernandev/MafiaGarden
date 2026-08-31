extends SceneTree
## Captura poses de un personaje para inspeccionar manos y arma.
## godot --path MafiaGardenGodot -s res://scripts/editor/shoot_anim.gd -- [--scene res://x.tscn] [--keep-weapon] anim1 anim2
##
## Por defecto oculta el arma para juzgar la MANO; --keep-weapon la deja visible.

const DEFAULT_SCENE := "res://soldado_anim.tscn"
const OUT_DIR := "res://review_shots/poses"


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var args := OS.get_cmdline_user_args()
	var scene_path := DEFAULT_SCENE
	var keep_weapon := false
	var names: Array = []
	var i := 0
	while i < args.size():
		var a := str(args[i])
		if a == "--scene" and i + 1 < args.size():
			scene_path = str(args[i + 1])
			i += 2
			continue
		if a == "--keep-weapon":
			keep_weapon = true
			i += 1
			continue
		names.append(a)
		i += 1
	if names.is_empty():
		names = ["mixamo_com_001", "IdleSoldado"]
	var tag := scene_path.get_file().get_basename()

	var world := Node3D.new()
	root.add_child(world)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45.0, -30.0, 0.0)
	light.light_energy = 1.6
	world.add_child(light)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.42, 0.45, 0.5)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.75)
	e.ambient_light_energy = 1.0
	env.environment = e
	world.add_child(env)

	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		print("[Shoot] FAIL no scene %s" % scene_path)
		quit(1)
		return
	var soldado: Node3D = packed.instantiate() as Node3D
	world.add_child(soldado)

	if not keep_weapon:
		var rifle := soldado.find_child("Rifle", true, false)
		if rifle:
			(rifle as Node3D).visible = false
	soldado.set("workshop_mode", true)
	soldado.set("calibration_debug", false)
	soldado.set("debug_show_markers", false)

	var cam := Camera3D.new()
	world.add_child(cam)

	for _i in 15:
		await process_frame

	var player := _find(soldado, "AnimationPlayer") as AnimationPlayer
	var skel := _find(soldado, "Skeleton3D") as Skeleton3D
	if player == null or skel == null:
		print("[Shoot] FAIL player/skel")
		quit(1)
		return

	for raw in names:
		var anim_name := str(raw)
		if not player.has_animation(anim_name):
			print("[Shoot] %s -> no existe" % anim_name)
			continue
		player.play(anim_name)
		player.seek(0.0, true)
		for _i in 10:
			await process_frame

		var l_idx := _bone(skel, "lefthand")
		var r_idx := _bone(skel, "righthand")
		if l_idx < 0 or r_idx < 0:
			print("[Shoot] %s -> sin huesos de mano" % anim_name)
			continue
		var l_w: Vector3 = (skel.global_transform * skel.get_bone_global_pose(l_idx)).origin
		var r_w: Vector3 = (skel.global_transform * skel.get_bone_global_pose(r_idx)).origin
		var grip := soldado.find_child("Grip", true, false) as Node3D
		var fore := soldado.find_child("Foregrip", true, false) as Node3D
		var muz := soldado.find_child("Muzzle", true, false) as Node3D
		var grip_err: float = grip.global_position.distance_to(r_w) if grip else -1.0
		var fore_err: float = fore.global_position.distance_to(l_w) if fore else -1.0
		var barrel_deg := -1.0
		var mag_deg := -1.0
		if grip and muz:
			var barrel: Vector3 = muz.global_position - grip.global_position
			var hands_dir: Vector3 = l_w - r_w
			if barrel.length_squared() > 0.0 and hands_dir.length_squared() > 0.0:
				barrel_deg = rad_to_deg(barrel.angle_to(hands_dir))
			# El cargador cuelga por +Z local del arma; debe mirar hacia abajo.
			mag_deg = rad_to_deg(grip.global_transform.basis.z.angle_to(Vector3.DOWN))
		print(
			"[Shoot] %-26s manos=%.3f grip_vs_R=%.4f fore_vs_L=%.4f canon_vs_manos=%.1f cargador_vs_abajo=%.1f"
			% [anim_name, l_w.distance_to(r_w), grip_err, fore_err, barrel_deg, mag_deg]
		)

		# Plano general y primer plano de cada mano.
		var focus: Vector3 = (l_w + r_w) * 0.5
		var la := _bone(skel, "leftarm")
		var ra := _bone(skel, "rightarm")
		var cam_dir := Vector3(1.6, 0.25, 1.2)
		if la >= 0 and ra >= 0:
			var la_w: Vector3 = (skel.global_transform * skel.get_bone_global_pose(la)).origin
			var ra_w: Vector3 = (skel.global_transform * skel.get_bone_global_pose(ra)).origin
			var lat: Vector3 = (ra_w - la_w).normalized()
			# Vista 3/4 desde el frente del cuerpo, no desde un eje de mundo fijo.
			cam_dir = (Vector3.UP.cross(lat) * 1.0 + lat * 0.55 + Vector3.UP * 0.18).normalized()
		_aim(cam, focus, cam_dir, 1.15)
		await _shot("%s/%s_%s_full.jpg" % [OUT_DIR, tag, anim_name])
		_aim(cam, r_w, Vector3(1.0, 0.5, 1.0), 0.30)
		await _shot("%s/%s_%s_manoR.jpg" % [OUT_DIR, tag, anim_name])
		_aim(cam, l_w, Vector3(1.0, 0.5, 1.0), 0.30)
		await _shot("%s/%s_%s_manoL.jpg" % [OUT_DIR, tag, anim_name])

	print("[Shoot] done %s" % ProjectSettings.globalize_path(OUT_DIR))
	quit(0)


func _aim(cam: Camera3D, focus: Vector3, dir: Vector3, dist: float) -> void:
	cam.global_position = focus + dir.normalized() * dist
	cam.look_at(focus, Vector3.UP)


func _shot(path: String) -> void:
	for _i in 4:
		await process_frame
	var tex := root.get_viewport().get_texture()
	if tex == null:
		return
	var img := tex.get_image()
	if img and not img.is_empty():
		img.save_jpg(path, 0.92)


func _bone(skel: Skeleton3D, suffix: String) -> int:
	for i in skel.get_bone_count():
		if skel.get_bone_name(i).to_lower().ends_with(suffix):
			return i
	return -1


func _find(node: Node, cls: String) -> Node:
	if node.is_class(cls):
		return node
	for c in node.get_children():
		var f := _find(c, cls)
		if f:
			return f
	return null
