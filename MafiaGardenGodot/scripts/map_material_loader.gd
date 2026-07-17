extends RefCounted
class_name MapMaterialLoader

## Carga materiales PBR desde res://textures/map/<carpeta>/


static func try_pbr_mat(
	folder: String,
	uv_scale: float,
	fallback_base: Color,
	fallback_accent: Color,
	fallback_rough: float,
	metallic: float = 0.0
) -> StandardMaterial3D:
	var dir := "res://textures/map/%s" % folder
	var albedo_path := "%s/albedo.jpg" % dir
	if not ResourceLoader.exists(albedo_path):
		var mat := noise_mat(fallback_base, fallback_accent, 0.12, uv_scale, fallback_rough)
		mat.metallic = metallic
		return mat

	var pbr := StandardMaterial3D.new()
	pbr.albedo_texture = load(albedo_path)
	pbr.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	pbr.metallic = metallic
	pbr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

	var normal_path := "%s/normal.jpg" % dir
	if ResourceLoader.exists(normal_path):
		pbr.normal_enabled = true
		pbr.normal_texture = load(normal_path)

	var rough_path := "%s/roughness.jpg" % dir
	if ResourceLoader.exists(rough_path):
		pbr.roughness_texture = load(rough_path)
	else:
		pbr.roughness = fallback_rough

	var ao_path := "%s/ao.jpg" % dir
	if ResourceLoader.exists(ao_path):
		pbr.ao_enabled = true
		pbr.ao_texture = load(ao_path)

	print("[MapMaterial] PBR cargado: ", folder)
	return pbr


static func noise_mat(
	base: Color, _accent: Color, freq: float, uv_scale: float, rough: float
) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = freq
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = base
	mat.roughness = rough
	mat.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	return mat


static func flat_mat(color: Color, rough: float, metal: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	mat.metallic = metal
	return mat
