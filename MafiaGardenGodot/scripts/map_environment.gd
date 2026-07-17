extends Node
class_name MapEnvironment

## Sol, cielo procedural, niebla y post-proceso (SSAO/glow). Ajustado para móvil.

@export_range(0.5, 2.5, 0.05) var sun_energy := 1.35
@export var sun_rotation_deg := Vector3(-48.0, -35.0, 0.0)
@export var enable_ssao := false
@export var enable_glow := true
@export var fog_density := 0.0018


func _ready() -> void:
	_apply_barrio_defaults()
	_setup_environment()
	_setup_sun()


func _apply_barrio_defaults() -> void:
	var barrio: BarrioData = GameState.get_selected_barrio()
	if barrio == null:
		return
	sun_energy = barrio.sun_energy
	fog_density = barrio.fog_density


func _is_mobile() -> bool:
	return OS.has_feature("mobile")


func _renderer_supports_ssao() -> bool:
	var method: String = ProjectSettings.get_setting(
		"rendering/renderer/rendering_method", "forward_plus"
	)
	return method != "mobile"


func _setup_environment() -> void:
	var env_node := WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env := Environment.new()

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.38, 0.52, 0.78)
	sky_mat.sky_horizon_color = Color(0.58, 0.64, 0.72)
	sky_mat.ground_bottom_color = Color(0.22, 0.2, 0.18)
	sky_mat.ground_horizon_color = Color(0.48, 0.5, 0.54)
	sky_mat.sun_angle_max = 35.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.35

	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05

	env.fog_enabled = true
	env.fog_light_color = Color(0.62, 0.66, 0.74)
	env.fog_density = fog_density
	env.fog_aerial_perspective = 0.22

	if enable_ssao and _renderer_supports_ssao():
		env.ssao_enabled = true
		if _is_mobile():
			env.ssao_radius = 0.75
			env.ssao_intensity = 0.9
			env.ssao_power = 1.4
		else:
			env.ssao_radius = 1.2
			env.ssao_intensity = 1.5
			env.ssao_power = 1.8

	if enable_glow:
		env.glow_enabled = true
		env.glow_intensity = 0.35
		env.glow_bloom = 0.12
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

	env_node.environment = env
	add_child(env_node)


func _setup_sun() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = sun_rotation_deg
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = sun_energy
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 45.0
	sun.shadow_bias = 0.05
	sun.shadow_normal_bias = 1.2
	sun.light_angular_distance = 0.85 if _is_mobile() else 0.55

	add_child(sun)
