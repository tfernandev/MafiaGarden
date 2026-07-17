extends RefCounted
class_name SquadCatalog

## Reclutas profesionales de la taberna. Todos se compran; los ligados a
## un barrio recién se pueden contratar tras conquistarlo.

const COMPANIONS: Dictionary = {
	"rico": {
		"display_name": "Rico",
		"desc": "Veterano del puerto. Buen equilibrio.",
		"unlock_after_barrio": "puerto_contrabando",
		"shop_cost": 550,
		"max_health": 95.0,
		"damage": 10.0,
		"follow_distance": 3.2,
		"tint": Color(0.65, 0.85, 0.95),
	},
	"luna": {
		"display_name": "Luna",
		"desc": "Tiradora del casino. Más vida, más daño.",
		"unlock_after_barrio": "casino_royal",
		"shop_cost": 700,
		"max_health": 110.0,
		"damage": 12.0,
		"follow_distance": 3.8,
		"tint": Color(0.95, 0.7, 0.85),
	},
	"maton": {
		"display_name": "Matón",
		"desc": "Soldado de alquiler. Siempre disponible en la taberna.",
		"unlock_after_barrio": "",
		"shop_cost": 420,
		"max_health": 80.0,
		"damage": 9.0,
		"follow_distance": 3.0,
		"tint": Color(0.75, 0.78, 0.72),
	},
}


static func get_def(companion_id: String) -> Dictionary:
	return COMPANIONS.get(companion_id, {})


static func get_all_ids() -> Array[String]:
	var out: Array[String] = []
	for id in COMPANIONS.keys():
		out.append(str(id))
	return out


## True si el recluta ya puede comprarse (sin barrio requerido o barrio conquistado).
static func is_purchase_unlocked(companion_id: String, progress: Dictionary) -> bool:
	var def: Dictionary = get_def(companion_id)
	if def.is_empty():
		return false
	var need: String = str(def.get("unlock_after_barrio", ""))
	if need.is_empty():
		return true
	var row: Dictionary = progress.get(need, {})
	return bool(row.get("cleared", false))


static func get_barrio_display_name(barrio_id: String) -> String:
	var barrio := BarrioCatalog.get_by_id(barrio_id)
	return barrio.display_name if barrio != null else barrio_id
