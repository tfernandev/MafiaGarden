extends RefCounted
class_name BarrioData

## Datos de un barrio del mapa estrategia + configuración del asalto.

var id: String = ""
var display_name: String = ""
var description: String = ""
var faction_name: String = "Los Lobos"
var faction_color: Color = Color(0.85, 0.25, 0.22)
var geometry_preset: String = "standard"
var props_preset: String = "default"
var map_scene: String = "res://scenes/street_map_v2.tscn"
var spawn_layout: String = "default"
var wave_counts: Array[int] = [1, 2, 2]
var wave_delays: Array[float] = [0.5, 2.5, 3.0]
## IDs de EnemyCatalog usados en las oleadas de este barrio.
var enemy_pool: Array[String] = ["thug"]
var influence_reward: int = 25
var money_reward: int = 400
var energy_cost: int = 10
var rent_per_minute: int = 8
var start_player_influence: int = 30
var start_rival_influence: int = 70
var unlock_after: String = ""
var fog_density: float = 0.0018
var sun_energy: float = 1.35


func _init(data: Dictionary = {}) -> void:
	id = str(data.get("id", ""))
	display_name = str(data.get("display_name", id))
	description = str(data.get("description", ""))
	faction_name = str(data.get("faction_name", "Los Lobos"))
	faction_color = data.get("faction_color", Color(0.85, 0.25, 0.22))
	geometry_preset = str(data.get("geometry_preset", "standard"))
	props_preset = str(data.get("props_preset", "default"))
	map_scene = str(data.get("map_scene", "res://scenes/street_map_v2.tscn"))
	spawn_layout = str(data.get("spawn_layout", "default"))
	wave_counts.assign(data.get("wave_counts", [1, 2, 2]))
	wave_delays.assign(data.get("wave_delays", [0.5, 2.5, 3.0]))
	enemy_pool.clear()
	var pool_raw: Variant = data.get("enemy_pool", ["thug"])
	if pool_raw is Array:
		for item in pool_raw:
			enemy_pool.append(str(item))
	if enemy_pool.is_empty():
		enemy_pool.append("thug")
	influence_reward = int(data.get("influence_reward", 25))
	money_reward = int(data.get("money_reward", 400))
	energy_cost = int(data.get("energy_cost", 10))
	rent_per_minute = int(data.get("rent_per_minute", 8))
	start_player_influence = int(data.get("start_player_influence", 30))
	start_rival_influence = int(data.get("start_rival_influence", 70))
	unlock_after = str(data.get("unlock_after", ""))
	fog_density = float(data.get("fog_density", 0.0018))
	sun_energy = float(data.get("sun_energy", 1.35))


func is_unlocked(progress: Dictionary) -> bool:
	if unlock_after.is_empty():
		return true
	var prev: Dictionary = progress.get(unlock_after, {})
	return bool(prev.get("cleared", false))


func is_controlled(progress: Dictionary) -> bool:
	var row: Dictionary = progress.get(id, {})
	return int(row.get("player", 0)) >= 100
