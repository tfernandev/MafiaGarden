extends RefCounted
class_name BarrioCatalog

const _RAW: Array[Dictionary] = [
	{
		"id": "puerto_contrabando",
		"display_name": "Puerto de Contrabando",
		"description": "Muelles, contenedores y combustible. Buen primer golpe para financiar la banda.",
		"faction_name": "Sindicato del Río",
		"faction_color": Color(0.25, 0.55, 0.82),
		"geometry_preset": "wide",
		"props_preset": "port",
		"map_scene": "res://scenes/maps/map_puerto.tscn",
		"spawn_layout": "wide_front",
		"wave_counts": [2, 2],
		"wave_delays": [0.4, 1.8],
		"enemy_pool": ["thug"],
		"influence_reward": 30,
		"money_reward": 380,
		"energy_cost": 8,
		"rent_per_minute": 8,
		"start_player_influence": 40,
		"start_rival_influence": 60,
		"fog_density": 0.0024,
		"sun_energy": 1.15,
	},
	{
		"id": "comisaria_sur",
		"display_name": "Comisaría Sur",
		"description": "Zona policial con patrullas y barricadas. Tomarla reduce presión rival.",
		"faction_name": "Distrito Azul",
		"faction_color": Color(0.2, 0.46, 0.95),
		"geometry_preset": "standard",
		"props_preset": "default",
		"map_scene": "res://scenes/maps/map_comisaria.tscn",
		"spawn_layout": "default",
		"wave_counts": [2, 2, 2],
		"wave_delays": [0.5, 2.0, 2.4],
		"enemy_pool": ["thug", "guard"],
		"influence_reward": 25,
		"money_reward": 420,
		"energy_cost": 10,
		"rent_per_minute": 10,
		"start_player_influence": 25,
		"start_rival_influence": 75,
		"unlock_after": "puerto_contrabando",
		"fog_density": 0.0016,
		"sun_energy": 1.3,
	},
	{
		"id": "joyeria_centro",
		"display_name": "Joyería Centro",
		"description": "Plaza de lujo con vitrinas caras y calles estrechas alrededor.",
		"faction_name": "Los Diamantes",
		"faction_color": Color(0.92, 0.76, 0.38),
		"geometry_preset": "alleys",
		"props_preset": "market",
		"map_scene": "res://scenes/maps/map_joyeria.tscn",
		"spawn_layout": "alleys",
		"wave_counts": [2, 2, 2],
		"wave_delays": [0.5, 2.0, 2.4],
		"enemy_pool": ["thug", "guard"],
		"influence_reward": 25,
		"money_reward": 560,
		"energy_cost": 11,
		"rent_per_minute": 12,
		"start_player_influence": 20,
		"start_rival_influence": 80,
		"unlock_after": "comisaria_sur",
		"fog_density": 0.0015,
		"sun_energy": 1.4,
	},
	{
		"id": "casino_royal",
		"display_name": "Casino Royal",
		"description": "Neones, dinero rápido y guardias apostados en cada esquina.",
		"faction_name": "La Corona Roja",
		"faction_color": Color(0.86, 0.18, 0.68),
		"geometry_preset": "dense",
		"props_preset": "dense",
		"map_scene": "res://scenes/maps/map_casino.tscn",
		"spawn_layout": "dense_flank",
		"wave_counts": [2, 3, 2],
		"wave_delays": [0.5, 2.0, 2.6],
		"enemy_pool": ["thug", "guard", "elite"],
		"influence_reward": 24,
		"money_reward": 720,
		"energy_cost": 13,
		"rent_per_minute": 16,
		"start_player_influence": 15,
		"start_rival_influence": 85,
		"unlock_after": "joyeria_centro",
		"fog_density": 0.0020,
		"sun_energy": 1.1,
	},
	{
		"id": "sindicato_camioneros",
		"display_name": "Sindicato de Camioneros",
		"description": "Depósitos, trailers y rutas de carga. Quien lo controla mueve la mercadería de la ciudad.",
		"faction_name": "Los Ruedas",
		"faction_color": Color(0.55, 0.42, 0.28),
		"geometry_preset": "wide",
		"props_preset": "dense",
		"map_scene": "res://scenes/maps/map_sindicato.tscn",
		"spawn_layout": "wide_front",
		"wave_counts": [2, 3, 2],
		"wave_delays": [0.5, 2.1, 2.7],
		"enemy_pool": ["thug", "guard"],
		"influence_reward": 24,
		"money_reward": 640,
		"energy_cost": 13,
		"rent_per_minute": 15,
		"start_player_influence": 15,
		"start_rival_influence": 85,
		"unlock_after": "casino_royal",
		"fog_density": 0.0022,
		"sun_energy": 1.2,
	},
	{
		"id": "capitolio",
		"display_name": "Capitolio",
		"description": "Edificio cívico central. Mucha visibilidad, poca cobertura.",
		"faction_name": "Guardia Civil",
		"faction_color": Color(0.78, 0.62, 0.36),
		"geometry_preset": "downtown",
		"props_preset": "default",
		"map_scene": "res://scenes/maps/map_capitolio.tscn",
		"spawn_layout": "plaza",
		"wave_counts": [2, 3, 3],
		"wave_delays": [0.6, 2.3, 2.8],
		"enemy_pool": ["guard", "elite"],
		"influence_reward": 28,
		"money_reward": 620,
		"energy_cost": 14,
		"rent_per_minute": 18,
		"start_player_influence": 10,
		"start_rival_influence": 90,
		"unlock_after": "sindicato_camioneros",
		"fog_density": 0.0014,
		"sun_energy": 1.45,
	},
	{
		"id": "plaza_civica",
		"display_name": "Plaza Cívica",
		"description": "Parque y avenidas debajo del Capitolio. Buen punto de control del centro.",
		"faction_name": "Guardia Urbana",
		"faction_color": Color(0.35, 0.72, 0.55),
		"geometry_preset": "old_town",
		"props_preset": "default",
		"map_scene": "res://scenes/maps/map_plaza.tscn",
		"spawn_layout": "plaza",
		"wave_counts": [2, 2, 3],
		"wave_delays": [0.5, 2.2, 2.6],
		"enemy_pool": ["thug", "guard"],
		"influence_reward": 22,
		"money_reward": 480,
		"energy_cost": 12,
		"rent_per_minute": 12,
		"start_player_influence": 15,
		"start_rival_influence": 85,
		"unlock_after": "capitolio",
		"fog_density": 0.0017,
		"sun_energy": 1.35,
	},
	{
		"id": "banco_central",
		"display_name": "Banco Central",
		"description": "El golpe clásico: bóvedas, columnas y seguridad privada.",
		"faction_name": "Custodios Dorados",
		"faction_color": Color(0.95, 0.72, 0.22),
		"geometry_preset": "downtown",
		"props_preset": "default",
		"map_scene": "res://scenes/maps/map_banco.tscn",
		"spawn_layout": "fortress",
		"wave_counts": [3, 3, 3],
		"wave_delays": [0.6, 2.2, 2.8],
		"enemy_pool": ["guard", "elite"],
		"influence_reward": 30,
		"money_reward": 900,
		"energy_cost": 15,
		"rent_per_minute": 22,
		"start_player_influence": 10,
		"start_rival_influence": 90,
		"unlock_after": "plaza_civica",
		"fog_density": 0.0013,
		"sun_energy": 1.5,
	},
	{
		"id": "mercado_nocturno",
		"display_name": "Mercado Nocturno",
		"description": "Puestos, callejones y cajas de mercadería para cubrirse.",
		"faction_name": "Los Puesteros",
		"faction_color": Color(0.92, 0.55, 0.18),
		"geometry_preset": "alleys",
		"props_preset": "market",
		"map_scene": "res://scenes/maps/map_mercado.tscn",
		"spawn_layout": "alleys",
		"wave_counts": [2, 3, 3],
		"wave_delays": [0.5, 2.0, 2.6],
		"enemy_pool": ["thug", "guard", "elite"],
		"influence_reward": 25,
		"money_reward": 520,
		"energy_cost": 12,
		"rent_per_minute": 14,
		"start_player_influence": 15,
		"start_rival_influence": 85,
		"unlock_after": "banco_central",
		"fog_density": 0.0026,
		"sun_energy": 0.95,
	},
	{
		"id": "mansion_dorada",
		"display_name": "Mansión Dorada",
		"description": "Complejo privado y fortificado. El cierre del capítulo.",
		"faction_name": "Familia Dorada",
		"faction_color": Color(0.72, 0.58, 0.28),
		"geometry_preset": "mansion",
		"props_preset": "dense",
		"map_scene": "res://scenes/maps/map_mansion.tscn",
		"spawn_layout": "fortress",
		"wave_counts": [3, 3, 4],
		"wave_delays": [0.7, 2.4, 3.0],
		"enemy_pool": ["guard", "elite", "elite"],
		"influence_reward": 35,
		"money_reward": 1000,
		"energy_cost": 17,
		"rent_per_minute": 28,
		"start_player_influence": 5,
		"start_rival_influence": 95,
		"unlock_after": "mercado_nocturno",
		"fog_density": 0.0018,
		"sun_energy": 1.25,
	},
]


static func get_all() -> Array[BarrioData]:
	var out: Array[BarrioData] = []
	for row in _RAW:
		out.append(BarrioData.new(row))
	return out


static func get_by_id(barrio_id: String) -> BarrioData:
	for row in _RAW:
		if str(row.get("id", "")) == barrio_id:
			return BarrioData.new(row)
	return null


static func get_map_position(barrio_id: String) -> Vector2:
	var poly := get_quadrant_polygon(barrio_id)
	if poly.is_empty():
		poly = get_map_polygon(barrio_id)
	if poly.is_empty():
		return Vector2(0.5, 0.5)
	var sum := Vector2.ZERO
	for p in poly:
		sum += p
	return sum / float(poly.size())


static func get_barrio_quadrant(barrio_id: String) -> String:
	match barrio_id:
		"puerto_contrabando", "casino_royal", "sindicato_camioneros":
			return "superior_izquierda"
		"banco_central":
			return "superior_derecha"
		"joyeria_centro", "capitolio", "plaza_civica", "comisaria_sur":
			return "inferior_izquierda"
		"mercado_nocturno", "mansion_dorada":
			return "inferior_derecha"
		_:
			return ""


static func get_barrios_for_quadrant(quadrant_id: String) -> Array[String]:
	match quadrant_id:
		"superior_izquierda":
			return ["puerto_contrabando", "casino_royal", "sindicato_camioneros"]
		"superior_derecha":
			return ["banco_central"]
		"inferior_izquierda":
			return ["comisaria_sur", "joyeria_centro", "capitolio", "plaza_civica"]
		"inferior_derecha":
			return ["mercado_nocturno", "mansion_dorada"]
		_:
			return []


static func get_quadrant_texture_path(quadrant_id: String) -> String:
	match quadrant_id:
		"superior_izquierda":
			return "res://textures/map/city/quadrants/superior_izquierda.png"
		"superior_derecha":
			return "res://textures/map/city/quadrants/superior_derecha.png"
		"inferior_izquierda":
			return "res://textures/map/city/quadrants/inferior_izquierda.png"
		"inferior_derecha":
			return "res://textures/map/city/quadrants/inferior_derecha.png"
		_:
			return ""


## Polígono 0–1 dentro del cuadrante (una pantalla = un tile).
static func get_quadrant_polygon(barrio_id: String) -> PackedVector2Array:
	match barrio_id:
		"puerto_contrabando", "casino_royal", "banco_central", "comisaria_sur", "joyeria_centro", "capitolio", "plaza_civica", "sindicato_camioneros", "mercado_nocturno", "mansion_dorada":
			return PackedVector2Array([
				Vector2(0.03, 0.03), Vector2(0.97, 0.03),
				Vector2(0.97, 0.97), Vector2(0.03, 0.97),
			])
		_:
			return PackedVector2Array()


## Zonas automáticas iniciales sobre city_map_isometric.png.
## Tip: Shift+clic en el mapa imprime Vector2(x, y) para reemplazar cualquier zona a mano.
static func get_map_polygon(barrio_id: String) -> PackedVector2Array:
	match barrio_id:
		"puerto_contrabando":
			return PackedVector2Array([
				Vector2(0.021, 0.237), Vector2(0.043, 0.219), Vector2(0.067, 0.192),
				Vector2(0.088, 0.180), Vector2(0.110, 0.151), Vector2(0.144, 0.127),
				Vector2(0.166, 0.122), Vector2(0.184, 0.130), Vector2(0.213, 0.106),
				Vector2(0.235, 0.088), Vector2(0.269, 0.063), Vector2(0.303, 0.029),
				Vector2(0.335, 0.024), Vector2(0.348, 0.049), Vector2(0.364, 0.063),
				Vector2(0.392, 0.094), Vector2(0.413, 0.114), Vector2(0.423, 0.133),
				Vector2(0.444, 0.159), Vector2(0.436, 0.175), Vector2(0.390, 0.211),
				Vector2(0.366, 0.231), Vector2(0.353, 0.250), Vector2(0.328, 0.265),
				Vector2(0.294, 0.291), Vector2(0.272, 0.308), Vector2(0.248, 0.341),
				Vector2(0.225, 0.367), Vector2(0.190, 0.399), Vector2(0.162, 0.414),
				Vector2(0.136, 0.422), Vector2(0.105, 0.407), Vector2(0.091, 0.375),
				Vector2(0.118, 0.357), Vector2(0.145, 0.338), Vector2(0.175, 0.308),
				Vector2(0.224, 0.279), Vector2(0.256, 0.245), Vector2(0.284, 0.214),
				Vector2(0.284, 0.198), Vector2(0.267, 0.183), Vector2(0.234, 0.195),
				Vector2(0.215, 0.213), Vector2(0.197, 0.231), Vector2(0.169, 0.252),
				Vector2(0.142, 0.269), Vector2(0.126, 0.284), Vector2(0.106, 0.300),
				Vector2(0.098, 0.308), Vector2(0.088, 0.312), Vector2(0.070, 0.294),
				Vector2(0.060, 0.281), Vector2(0.043, 0.265), Vector2(0.038, 0.258),
				Vector2(0.030, 0.253),
			])
		"comisaria_sur":
			return PackedVector2Array([
				Vector2(0.419, 0.713), Vector2(0.218, 0.513), Vector2(0.166, 0.583),
				Vector2(0.131, 0.640), Vector2(0.131, 0.664), Vector2(0.157, 0.690),
				Vector2(0.176, 0.716), Vector2(0.188, 0.740), Vector2(0.174, 0.765),
				Vector2(0.194, 0.792), Vector2(0.227, 0.802), Vector2(0.247, 0.820),
				Vector2(0.263, 0.831), Vector2(0.295, 0.800), Vector2(0.310, 0.807),
			])
		"joyeria_centro":
			return PackedVector2Array([
				Vector2(0.340, 0.589), Vector2(0.306, 0.568), Vector2(0.289, 0.544),
				Vector2(0.267, 0.521), Vector2(0.248, 0.505), Vector2(0.241, 0.494),
				Vector2(0.254, 0.466), Vector2(0.279, 0.443), Vector2(0.293, 0.427),
				Vector2(0.310, 0.406), Vector2(0.333, 0.378), Vector2(0.357, 0.354),
				Vector2(0.389, 0.336), Vector2(0.410, 0.310), Vector2(0.455, 0.360),
				Vector2(0.473, 0.394), Vector2(0.485, 0.416), Vector2(0.447, 0.458),
				Vector2(0.410, 0.511), Vector2(0.397, 0.521), Vector2(0.379, 0.554),
				Vector2(0.361, 0.568),
			])
		"casino_royal":
			return PackedVector2Array([
				Vector2(0.429, 0.216), Vector2(0.448, 0.198), Vector2(0.466, 0.175),
				Vector2(0.488, 0.156), Vector2(0.509, 0.135), Vector2(0.527, 0.117),
				Vector2(0.542, 0.096), Vector2(0.556, 0.076), Vector2(0.575, 0.060),
				Vector2(0.590, 0.055), Vector2(0.617, 0.075), Vector2(0.622, 0.094),
				Vector2(0.637, 0.123), Vector2(0.649, 0.135), Vector2(0.675, 0.157),
				Vector2(0.693, 0.183), Vector2(0.701, 0.195), Vector2(0.671, 0.227),
				Vector2(0.648, 0.245), Vector2(0.634, 0.263), Vector2(0.607, 0.294),
				Vector2(0.580, 0.321), Vector2(0.549, 0.346), Vector2(0.528, 0.380),
				Vector2(0.512, 0.381), Vector2(0.487, 0.369), Vector2(0.464, 0.352),
				Vector2(0.447, 0.318), Vector2(0.399, 0.286), Vector2(0.386, 0.266),
				Vector2(0.413, 0.234),
			])
		"sindicato_camioneros":
			return PackedVector2Array([
				Vector2(0.670, 0.240), Vector2(0.702, 0.213), Vector2(0.735, 0.182),
				Vector2(0.779, 0.136), Vector2(0.814, 0.123), Vector2(0.843, 0.086),
				Vector2(0.863, 0.068), Vector2(0.887, 0.080), Vector2(0.908, 0.107),
				Vector2(0.944, 0.128), Vector2(0.956, 0.148), Vector2(0.970, 0.156),
				Vector2(0.990, 0.175), Vector2(0.984, 0.209), Vector2(0.956, 0.244),
				Vector2(0.924, 0.273), Vector2(0.896, 0.320), Vector2(0.874, 0.341),
				Vector2(0.856, 0.352), Vector2(0.845, 0.372), Vector2(0.831, 0.378),
				Vector2(0.802, 0.347), Vector2(0.761, 0.318), Vector2(0.722, 0.289),
				Vector2(0.711, 0.266), Vector2(0.688, 0.256),
			])
		"capitolio":
			return PackedVector2Array([
				Vector2(0.723, 0.700), Vector2(0.699, 0.672), Vector2(0.682, 0.654),
				Vector2(0.665, 0.643), Vector2(0.657, 0.628), Vector2(0.640, 0.614),
				Vector2(0.634, 0.606), Vector2(0.624, 0.602), Vector2(0.615, 0.589),
				Vector2(0.598, 0.573), Vector2(0.587, 0.560), Vector2(0.555, 0.537),
				Vector2(0.549, 0.523), Vector2(0.529, 0.498), Vector2(0.515, 0.482),
				Vector2(0.502, 0.466), Vector2(0.499, 0.440), Vector2(0.512, 0.427),
				Vector2(0.542, 0.398), Vector2(0.561, 0.390), Vector2(0.571, 0.378),
				Vector2(0.603, 0.373), Vector2(0.620, 0.406), Vector2(0.645, 0.440),
				Vector2(0.656, 0.456), Vector2(0.666, 0.472), Vector2(0.690, 0.482),
				Vector2(0.721, 0.502), Vector2(0.733, 0.519), Vector2(0.748, 0.541),
				Vector2(0.776, 0.555), Vector2(0.795, 0.586), Vector2(0.805, 0.594),
				Vector2(0.805, 0.617), Vector2(0.762, 0.661), Vector2(0.734, 0.693),
			])
		"plaza_civica":
			return PackedVector2Array([
				Vector2(0.432, 0.528), Vector2(0.457, 0.497), Vector2(0.475, 0.469),
				Vector2(0.495, 0.468), Vector2(0.498, 0.468), Vector2(0.504, 0.492),
				Vector2(0.514, 0.498), Vector2(0.527, 0.518), Vector2(0.532, 0.531),
				Vector2(0.535, 0.532), Vector2(0.554, 0.552), Vector2(0.571, 0.571),
				Vector2(0.579, 0.586), Vector2(0.584, 0.602), Vector2(0.562, 0.630),
				Vector2(0.548, 0.649), Vector2(0.518, 0.675), Vector2(0.496, 0.693),
				Vector2(0.474, 0.705), Vector2(0.464, 0.713), Vector2(0.448, 0.705),
				Vector2(0.437, 0.698), Vector2(0.425, 0.680), Vector2(0.411, 0.661),
				Vector2(0.385, 0.633), Vector2(0.367, 0.609), Vector2(0.360, 0.602),
				Vector2(0.377, 0.573), Vector2(0.417, 0.531), Vector2(0.432, 0.519),
			])
		"banco_central":
			return PackedVector2Array([
				Vector2(0.813, 0.550), Vector2(0.778, 0.516), Vector2(0.747, 0.490),
				Vector2(0.724, 0.469), Vector2(0.699, 0.445), Vector2(0.674, 0.429),
				Vector2(0.649, 0.406), Vector2(0.626, 0.381), Vector2(0.606, 0.369),
				Vector2(0.597, 0.357), Vector2(0.613, 0.339), Vector2(0.634, 0.320),
				Vector2(0.649, 0.302), Vector2(0.662, 0.289), Vector2(0.676, 0.282),
				Vector2(0.690, 0.273), Vector2(0.712, 0.295), Vector2(0.726, 0.312),
				Vector2(0.739, 0.326), Vector2(0.756, 0.330), Vector2(0.766, 0.331),
				Vector2(0.779, 0.331), Vector2(0.788, 0.343), Vector2(0.805, 0.356),
				Vector2(0.818, 0.372), Vector2(0.828, 0.391), Vector2(0.839, 0.412),
				Vector2(0.859, 0.433), Vector2(0.882, 0.458), Vector2(0.887, 0.474),
				Vector2(0.861, 0.500), Vector2(0.843, 0.518),
			])
		"mercado_nocturno":
			return PackedVector2Array([
				Vector2(0.343, 0.808), Vector2(0.419, 0.719), Vector2(0.457, 0.756),
				Vector2(0.604, 0.619), Vector2(0.698, 0.729), Vector2(0.478, 0.958),
			])
		"mansion_dorada":
			return PackedVector2Array([
				Vector2(0.867, 0.617), Vector2(0.603, 0.869), Vector2(0.709, 0.994),
				Vector2(0.834, 0.872), Vector2(0.905, 0.940), Vector2(0.999, 0.839),
				Vector2(0.999, 0.742),
			])
		_:
			return PackedVector2Array()


static func _box_poly(left: float, top: float, right: float, bottom: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(left, top), Vector2(right, top),
		Vector2(right, bottom), Vector2(left, bottom),
	])


static func _ellipse_poly(center: Vector2, radius: Vector2, steps: int = 12) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(steps):
		var t := TAU * float(i) / float(steps)
		out.append(center + Vector2(cos(t) * radius.x, sin(t) * radius.y))
	return out
