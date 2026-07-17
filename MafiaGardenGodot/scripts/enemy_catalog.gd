extends RefCounted
class_name EnemyCatalog

## Variantes de enemigo (mismo GLB, stats/tint distintos).

const DEFS: Dictionary = {
	"thug": {
		"display_name": "Matón",
		"max_health": 90.0,
		"damage": 8.0,
		"walk_speed": 3.5,
		"aim_accuracy": 0.5,
		"tint": Color(0.85, 0.55, 0.55),
	},
	"guard": {
		"display_name": "Guardia",
		"max_health": 120.0,
		"damage": 10.0,
		"walk_speed": 3.1,
		"aim_accuracy": 0.62,
		"tint": Color(0.55, 0.62, 0.85),
	},
	"elite": {
		"display_name": "Élite",
		"max_health": 145.0,
		"damage": 13.0,
		"walk_speed": 3.6,
		"aim_accuracy": 0.72,
		"fire_interval_min": 0.32,
		"fire_interval_max": 0.58,
		"tint": Color(0.95, 0.78, 0.35),
	},
}


static func pick_for_wave(pool: Array, wave_idx: int, slot: int) -> String:
	if pool.is_empty():
		return "thug"
	# Oleadas altas sesgan hacia el final del pool (élites).
	var bias: int = mini(wave_idx, pool.size() - 1)
	var idx: int = (slot + bias) % pool.size()
	return str(pool[idx])


static func apply(enemy: CharacterBody3D, enemy_id: String) -> void:
	var def: Dictionary = DEFS.get(enemy_id, DEFS["thug"])
	enemy.max_health = float(def.get("max_health", 100.0))
	enemy.health = enemy.max_health
	enemy.damage = float(def.get("damage", 9.0))
	enemy.walk_speed = float(def.get("walk_speed", 3.4))
	enemy.aim_accuracy = float(def.get("aim_accuracy", 0.58))
	if def.has("fire_interval_min"):
		enemy.fire_interval_min = float(def["fire_interval_min"])
	if def.has("fire_interval_max"):
		enemy.fire_interval_max = float(def["fire_interval_max"])
	enemy.set_meta("enemy_id", enemy_id)
	enemy.set_meta("enemy_name", str(def.get("display_name", enemy_id)))
	_apply_tint(enemy, def.get("tint", Color.WHITE))


static func _apply_tint(root: Node, tint: Color) -> void:
	if tint.is_equal_approx(Color.WHITE):
		return
	for child in root.get_children():
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			var base: Material = mi.get_active_material(0)
			if base is StandardMaterial3D:
				var dup := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
				dup.albedo_color = Color(
					dup.albedo_color.r * tint.r,
					dup.albedo_color.g * tint.g,
					dup.albedo_color.b * tint.b,
					dup.albedo_color.a
				)
				mi.material_override = dup
		_apply_tint(child, tint)
