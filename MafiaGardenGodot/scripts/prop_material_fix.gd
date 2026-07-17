extends RefCounted
class_name PropMaterialFix

## Re-enlaza texturas Poly Haven si el GLTF se importó antes de tener textures/.


static func apply(model: Node3D, scene_path: String) -> void:
	var tex_dir := "%s/textures" % scene_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(tex_dir):
		push_warning("PropMaterialFix: sin carpeta textures en ", scene_path.get_base_dir())
		return

	var diff := _find_texture(tex_dir, "diff")
	var nor := _find_texture(tex_dir, "nor_gl")
	var arm := _find_texture(tex_dir, "arm")

	if diff.is_empty() and nor.is_empty():
		return

	for mesh_inst in _all_mesh_instances(model):
		if mesh_inst.mesh == null:
			continue
		for surface_idx in mesh_inst.mesh.get_surface_count():
			var mat := _ensure_material(mesh_inst, surface_idx)
			if mat == null:
				continue
			var diff_tex := _try_load_texture(diff)
			if diff_tex:
				mat.albedo_texture = diff_tex
			var nor_tex := _try_load_texture(nor)
			if nor_tex:
				mat.normal_enabled = true
				mat.normal_texture = nor_tex
			var arm_tex := _try_load_texture(arm)
			if arm_tex:
				mat.ao_enabled = true
				mat.ao_texture = arm_tex
				mat.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
				mat.roughness_texture = arm_tex
				mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
				mat.metallic_texture = arm_tex
				mat.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
			mesh_inst.set_surface_override_material(surface_idx, mat)


static func _ensure_material(mesh_inst: MeshInstance3D, surface_idx: int) -> StandardMaterial3D:
	var mat := mesh_inst.get_surface_override_material(surface_idx)
	if mat == null and mesh_inst.mesh:
		mat = mesh_inst.mesh.surface_get_material(surface_idx)
	var std := mat as StandardMaterial3D
	if std:
		return std.duplicate() as StandardMaterial3D
	return StandardMaterial3D.new()


static func _try_load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path) as Texture2D


static func _find_texture(tex_dir: String, token: String) -> String:
	var dir := DirAccess.open(tex_dir)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".jpg") and token in file_name:
			return "%s/%s" % [tex_dir, file_name]
		file_name = dir.get_next()
	dir.list_dir_end()
	return ""


static func _all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var list: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		list.append(node)
	for child in node.get_children():
		list.append_array(_all_mesh_instances(child))
	return list
