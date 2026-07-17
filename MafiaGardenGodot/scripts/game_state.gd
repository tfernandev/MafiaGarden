extends Node

## Progresión global: recursos, renta, upgrades, barrio e influencia.

signal rent_collected(amount: int)
signal energy_gained(amount: int)
signal money_spent(amount: int)
signal friend_click_result(result: Dictionary)

const SAVE_PATH := "user://mafia_garden_save.json"
## Segundos reales por +1 energía (online y offline).
const ENERGY_REGEN_SECONDS := 40.0
## Tick de renta: 1 minuto de juego = 1 pago de rent_per_minute.
const RENT_TICK_SECONDS := 60.0
## Tope de acumulación offline de renta (8 horas).
const RENT_OFFLINE_CAP_SECONDS := 8.0 * 3600.0

const UPGRADE_DEFS: Dictionary = {
	"hp": {
		"name": "Blindaje",
		"desc": "+20 vida máxima por nivel",
		"max_level": 5,
		"base_cost": 280,
	},
	"damage": {
		"name": "Fuego pesado",
		"desc": "+4 daño por nivel",
		"max_level": 5,
		"base_cost": 320,
	},
	"energy_cap": {
		"name": "Reserva",
		"desc": "+15 energía máxima por nivel",
		"max_level": 4,
		"base_cost": 400,
	},
}

var selected_barrio_id: String = ""
var money: int = 1200
var energy: int = 100
var max_energy: int = 100
var barrio_progress: Dictionary = {}
## Niveles: hp, damage, energy_cap
var upgrades: Dictionary = {"hp": 0, "damage": 0, "energy_cap": 0}
## Reclutas en tu banda (ids de SquadCatalog o amigos del celular).
var owned_companions: Array[String] = []
## Reclutas elegidos para el próximo asalto.
var assault_selected: Array[String] = []
const MAX_ASSAULT_SLOTS := 2
## companion_id -> unix time en que vuelve a estar disponible.
var wounded_until: Dictionary = {}
## Horas reales de recuperación tras caer en un asalto.
const WOUND_RECOVERY_HOURS := 3.0

## --- Amigos del celular (clicker) ---
## id -> {name, base_health, base_damage, level, weapon, tint_html}
var friends: Dictionary = {}
var _friend_seq: int = 0
var friend_request_clicks: int = 0

const FRIEND_BASE_CAP := 1
const FRIENDS_PER_CONTROLLED_BARRIO := 1
const FRIEND_ABSOLUTE_CAP := 12
const FRIEND_MAX_LEVEL := 5
const FRIEND_BASE_ACCEPT_CHANCE := 0.25
const FRIEND_ACCEPT_BARRIO_BONUS := 0.02
const FRIEND_MAX_ACCEPT_CHANCE := 0.45
const FRIEND_BASE_CLICKS := 80
const FRIEND_CLICKS_PER_FRIEND := 45
const FRIEND_TRAIN_HP_PER_LEVEL := 10.0
const FRIEND_TRAIN_DMG_PER_LEVEL := 2.0

## Armas para amigos, en orden de compra (tier 0 = sin arma).
const FRIEND_WEAPONS: Array[Dictionary] = [
	{"name": "Sin arma", "damage_bonus": 0.0, "cost": 0},
	{"name": "Pistola", "damage_bonus": 3.0, "cost": 220},
	{"name": "Escopeta", "damage_bonus": 6.0, "cost": 480},
	{"name": "Rifle", "damage_bonus": 10.0, "cost": 850},
]

const FRIEND_NAMES: Array[String] = [
	"Marcos", "Tano", "Chino", "Piru", "Fede", "Gato", "Loco Ariel",
	"Nacho", "Turco", "Pipa", "Colo", "Ruso", "Mono", "Chueco",
]

var _energy_accum := 0.0
var _rent_accum := 0.0
var _last_energy_unix := 0.0
var _last_rent_unix := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_or_init()
	_apply_offline_energy()
	_apply_offline_rent()
	set_process(true)


func _process(delta: float) -> void:
	_tick_energy(delta)
	_tick_rent(delta)


func _tick_energy(delta: float) -> void:
	if energy >= max_energy:
		_energy_accum = 0.0
		return
	_energy_accum += delta
	if _energy_accum >= ENERGY_REGEN_SECONDS:
		var steps: int = int(_energy_accum / ENERGY_REGEN_SECONDS)
		_energy_accum = fmod(_energy_accum, ENERGY_REGEN_SECONDS)
		var before: int = energy
		energy = mini(energy + steps, max_energy)
		var gained: int = energy - before
		_last_energy_unix = Time.get_unix_time_from_system()
		save_game()
		if gained > 0:
			energy_gained.emit(gained)


func _tick_rent(delta: float) -> void:
	var rpm: int = get_rent_per_minute()
	if rpm <= 0:
		_rent_accum = 0.0
		return
	_rent_accum += delta
	if _rent_accum >= RENT_TICK_SECONDS:
		var ticks: int = int(_rent_accum / RENT_TICK_SECONDS)
		_rent_accum = fmod(_rent_accum, RENT_TICK_SECONDS)
		var payout: int = rpm * ticks
		money += payout
		_last_rent_unix = Time.get_unix_time_from_system()
		save_game()
		rent_collected.emit(payout)


func _load_or_init() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary:
				_apply_save(parsed)
				return
	_init_progress()
	var now := Time.get_unix_time_from_system()
	_last_energy_unix = now
	_last_rent_unix = now


func _init_progress() -> void:
	barrio_progress.clear()
	for barrio in BarrioCatalog.get_all():
		barrio_progress[barrio.id] = {
			"player": barrio.start_player_influence,
			"rival": barrio.start_rival_influence,
			"cleared": false,
		}
	upgrades = {"hp": 0, "damage": 0, "energy_cap": 0}
	owned_companions.clear()
	assault_selected.clear()
	friends.clear()
	wounded_until.clear()
	_friend_seq = 0
	friend_request_clicks = 0
	_recalc_max_energy()


func _apply_save(data: Dictionary) -> void:
	money = int(data.get("money", 1200))
	energy = int(data.get("energy", 100))
	max_energy = int(data.get("max_energy", 100))
	var now := Time.get_unix_time_from_system()
	_last_energy_unix = float(data.get("last_energy_unix", now))
	_last_rent_unix = float(data.get("last_rent_unix", now))
	var saved_up: Variant = data.get("upgrades", {})
	if saved_up is Dictionary:
		upgrades = {
			"hp": int(saved_up.get("hp", 0)),
			"damage": int(saved_up.get("damage", 0)),
			"energy_cap": int(saved_up.get("energy_cap", 0)),
		}
	else:
		upgrades = {"hp": 0, "damage": 0, "energy_cap": 0}
	var saved_progress: Variant = data.get("barrio_progress", {})
	if saved_progress is Dictionary and not saved_progress.is_empty():
		barrio_progress = saved_progress
	else:
		_init_progress()
	_ensure_catalog_progress()
	_load_friends_state(data)
	_load_companion_state(data)
	_recalc_max_energy()
	energy = mini(energy, max_energy)


func _load_companion_state(data: Dictionary) -> void:
	var saved_owned: Variant = data.get("owned_companions", null)
	if saved_owned is Array:
		owned_companions.clear()
		for raw_id in saved_owned:
			var id := str(raw_id)
			if not SquadCatalog.get_def(id).is_empty():
				owned_companions.append(id)
	else:
		owned_companions.clear()

	var saved_assault: Variant = data.get("assault_selected", null)
	if saved_assault is Array:
		assault_selected.clear()
		for raw_id in saved_assault:
			var id := str(raw_id)
			if owns_companion(id):
				assault_selected.append(id)
	validate_assault_selection()


func _load_friends_state(data: Dictionary) -> void:
	friends.clear()
	var saved_friends: Variant = data.get("friends", {})
	if saved_friends is Dictionary:
		for raw_id in saved_friends.keys():
			var id := str(raw_id)
			var row: Variant = saved_friends[raw_id]
			if row is Dictionary:
				friends[id] = row
	_friend_seq = int(data.get("friend_seq", friends.size()))
	friend_request_clicks = int(data.get("friend_request_clicks", 0))
	wounded_until.clear()
	var saved_wounded: Variant = data.get("wounded_until", {})
	if saved_wounded is Dictionary:
		for raw_id in saved_wounded.keys():
			wounded_until[str(raw_id)] = float(saved_wounded[raw_id])
	_clear_recovered_wounds()


func _apply_offline_energy() -> void:
	if _last_energy_unix <= 0.0:
		_last_energy_unix = Time.get_unix_time_from_system()
		return
	if energy >= max_energy:
		_last_energy_unix = Time.get_unix_time_from_system()
		return
	var now := Time.get_unix_time_from_system()
	var elapsed: float = maxf(0.0, now - _last_energy_unix)
	var gained: int = int(elapsed / ENERGY_REGEN_SECONDS)
	if gained > 0:
		energy = mini(energy + gained, max_energy)
		_last_energy_unix = now - fmod(elapsed, ENERGY_REGEN_SECONDS)
		save_game()
		energy_gained.emit(gained)


func _apply_offline_rent() -> void:
	if _last_rent_unix <= 0.0:
		_last_rent_unix = Time.get_unix_time_from_system()
		return
	var rpm: int = get_rent_per_minute()
	if rpm <= 0:
		_last_rent_unix = Time.get_unix_time_from_system()
		return
	var now := Time.get_unix_time_from_system()
	var elapsed: float = clampf(now - _last_rent_unix, 0.0, RENT_OFFLINE_CAP_SECONDS)
	var minutes: int = int(elapsed / RENT_TICK_SECONDS)
	if minutes > 0:
		var payout: int = rpm * minutes
		money += payout
		_last_rent_unix = now - fmod(elapsed, RENT_TICK_SECONDS)
		save_game()
		rent_collected.emit(payout)


func save_game() -> void:
	var data := {
		"money": money,
		"energy": energy,
		"max_energy": max_energy,
		"last_energy_unix": _last_energy_unix,
		"last_rent_unix": _last_rent_unix,
		"upgrades": upgrades,
		"barrio_progress": barrio_progress,
		"owned_companions": owned_companions,
		"assault_selected": assault_selected,
		"friends": friends,
		"friend_seq": _friend_seq,
		"friend_request_clicks": friend_request_clicks,
		"wounded_until": wounded_until,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func get_selected_barrio() -> BarrioData:
	if selected_barrio_id.is_empty():
		return BarrioCatalog.get_by_id("puerto_contrabando")
	var barrio := BarrioCatalog.get_by_id(selected_barrio_id)
	return barrio if barrio != null else BarrioCatalog.get_by_id("puerto_contrabando")


func _ensure_catalog_progress() -> void:
	# Permite cambiar el catálogo del mapa sin romper partidas guardadas viejas.
	for barrio in BarrioCatalog.get_all():
		if not barrio_progress.has(barrio.id):
			barrio_progress[barrio.id] = {
				"player": barrio.start_player_influence,
				"rival": barrio.start_rival_influence,
				"cleared": false,
			}


func get_barrio_row(barrio_id: String) -> Dictionary:
	return barrio_progress.get(barrio_id, {})


func get_rent_per_minute() -> int:
	var total := 0
	for barrio in BarrioCatalog.get_all():
		if barrio.is_controlled(barrio_progress):
			total += barrio.rent_per_minute
	return total


func get_controlled_count() -> int:
	var n := 0
	for barrio in BarrioCatalog.get_all():
		if barrio.is_controlled(barrio_progress):
			n += 1
	return n


func seconds_to_next_rent() -> float:
	if get_rent_per_minute() <= 0:
		return 0.0
	return maxf(0.0, RENT_TICK_SECONDS - _rent_accum)


func can_afford_assault(barrio: BarrioData) -> bool:
	return energy >= barrio.energy_cost


func spend_assault_energy(barrio: BarrioData) -> bool:
	if not can_afford_assault(barrio):
		return false
	energy -= barrio.energy_cost
	save_game()
	return true


func apply_assault_victory(barrio: BarrioData) -> Dictionary:
	var row: Dictionary = barrio_progress.get(barrio.id, {})
	var player_inf: int = int(row.get("player", barrio.start_player_influence))
	var rival_inf: int = int(row.get("rival", barrio.start_rival_influence))
	player_inf = mini(player_inf + barrio.influence_reward, 100)
	rival_inf = maxi(rival_inf - barrio.influence_reward, 0)
	if player_inf + rival_inf > 100:
		rival_inf = 100 - player_inf
	money += barrio.money_reward
	var cleared := player_inf >= 100
	barrio_progress[barrio.id] = {
		"player": player_inf,
		"rival": rival_inf,
		"cleared": cleared or bool(row.get("cleared", false)),
	}
	save_game()
	return {
		"player_influence": player_inf,
		"rival_influence": rival_inf,
		"money_gained": barrio.money_reward,
		"cleared": cleared,
		"rent_per_minute": get_rent_per_minute(),
	}


func get_upgrade_level(upgrade_id: String) -> int:
	return int(upgrades.get(upgrade_id, 0))


func get_upgrade_cost(upgrade_id: String) -> int:
	var def: Dictionary = UPGRADE_DEFS.get(upgrade_id, {})
	if def.is_empty():
		return 999999
	var level: int = get_upgrade_level(upgrade_id)
	var max_level: int = int(def.get("max_level", 1))
	if level >= max_level:
		return -1
	var base: int = int(def.get("base_cost", 300))
	return base + level * int(base * 0.65)


func can_buy_upgrade(upgrade_id: String) -> bool:
	var cost: int = get_upgrade_cost(upgrade_id)
	return cost > 0 and money >= cost


func buy_upgrade(upgrade_id: String) -> bool:
	if not can_buy_upgrade(upgrade_id):
		return false
	var cost: int = get_upgrade_cost(upgrade_id)
	money -= cost
	upgrades[upgrade_id] = get_upgrade_level(upgrade_id) + 1
	_recalc_max_energy()
	save_game()
	money_spent.emit(cost)
	return true


func _recalc_max_energy() -> void:
	var base := 100
	var bonus: int = get_upgrade_level("energy_cap") * 15
	max_energy = base + bonus
	energy = mini(energy, max_energy)


func get_player_max_health() -> float:
	return 100.0 + float(get_upgrade_level("hp")) * 20.0


func get_player_damage() -> float:
	return 12.0 + float(get_upgrade_level("damage")) * 4.0


func seconds_to_next_energy() -> float:
	if energy >= max_energy:
		return 0.0
	return maxf(0.0, ENERGY_REGEN_SECONDS - _energy_accum)


func owns_companion(companion_id: String) -> bool:
	return owned_companions.has(companion_id) or friends.has(companion_id)


func get_max_assault_slots() -> int:
	return MAX_ASSAULT_SLOTS


func validate_assault_selection() -> void:
	_clear_recovered_wounds()
	var valid: Array[String] = []
	for raw_id in assault_selected:
		var id := str(raw_id)
		if owns_companion(id) and not is_companion_wounded(id) and not valid.has(id):
			valid.append(id)
		if valid.size() >= get_max_assault_slots():
			break
	assault_selected = valid


func is_assault_selected(companion_id: String) -> bool:
	return assault_selected.has(companion_id)


func get_assault_squad_ids() -> Array[String]:
	validate_assault_selection()
	return assault_selected.duplicate()


func mark_companion_wounded(companion_id: String) -> void:
	if companion_id.is_empty() or not owns_companion(companion_id):
		return
	var recover_at := Time.get_unix_time_from_system() + WOUND_RECOVERY_HOURS * 3600.0
	wounded_until[companion_id] = recover_at
	if assault_selected.has(companion_id):
		assault_selected.erase(companion_id)
	save_game()


func is_companion_wounded(companion_id: String) -> bool:
	_clear_recovered_wounds()
	return wounded_until.has(companion_id)


func get_wound_seconds_left(companion_id: String) -> float:
	_clear_recovered_wounds()
	if not wounded_until.has(companion_id):
		return 0.0
	return maxf(0.0, float(wounded_until[companion_id]) - Time.get_unix_time_from_system())


func format_wound_time_left(companion_id: String) -> String:
	var left := get_wound_seconds_left(companion_id)
	if left <= 0.0:
		return ""
	var hours := int(left) / 3600
	var mins := (int(left) % 3600) / 60
	if hours > 0:
		return "%dh %02dm" % [hours, mins]
	return "%dm" % maxi(mins, 1)


func _clear_recovered_wounds() -> void:
	if wounded_until.is_empty():
		return
	var now := Time.get_unix_time_from_system()
	var changed := false
	var to_remove: Array[String] = []
	for raw_id in wounded_until.keys():
		if float(wounded_until[raw_id]) <= now:
			to_remove.append(str(raw_id))
	for id in to_remove:
		wounded_until.erase(id)
		changed = true
	if changed:
		save_game()


func get_roster_ids() -> Array[String]:
	var out: Array[String] = []
	for id in owned_companions:
		if not out.has(id):
			out.append(id)
	for raw_id in friends.keys():
		var id := str(raw_id)
		if not out.has(id):
			out.append(id)
	return out


func get_companion_def(companion_id: String) -> Dictionary:
	var catalog_def := SquadCatalog.get_def(companion_id)
	if not catalog_def.is_empty():
		var def := catalog_def.duplicate()
		def["id"] = companion_id
		return def
	if friends.has(companion_id):
		return get_friend_combat_def(companion_id)
	return {}


func get_companion_display_name(companion_id: String) -> String:
	var def := get_companion_def(companion_id)
	return str(def.get("display_name", companion_id))


func get_companion_names(companion_ids: Array) -> PackedStringArray:
	var names: PackedStringArray = ["Vos"]
	for raw_id in companion_ids:
		var id := str(raw_id)
		if owns_companion(id):
			names.append(get_companion_display_name(id))
	return names


func toggle_assault_selection(companion_id: String) -> bool:
	if not owns_companion(companion_id) or is_companion_wounded(companion_id):
		return false
	if assault_selected.has(companion_id):
		assault_selected.erase(companion_id)
		save_game()
		return true
	if assault_selected.size() >= get_max_assault_slots():
		return false
	assault_selected.append(companion_id)
	save_game()
	return true


func set_assault_selection(companion_ids: Array) -> void:
	assault_selected.clear()
	for raw_id in companion_ids:
		var id := str(raw_id)
		if not owns_companion(id) or is_companion_wounded(id) or assault_selected.has(id):
			continue
		assault_selected.append(id)
		if assault_selected.size() >= get_max_assault_slots():
			break
	save_game()


func get_friend_capacity() -> int:
	return mini(FRIEND_ABSOLUTE_CAP, FRIEND_BASE_CAP + get_controlled_count() * FRIENDS_PER_CONTROLLED_BARRIO)


func get_friend_count() -> int:
	return friends.size()


func get_friend_required_clicks() -> int:
	return FRIEND_BASE_CLICKS + get_friend_count() * FRIEND_CLICKS_PER_FRIEND


func get_friend_accept_chance() -> float:
	return minf(FRIEND_MAX_ACCEPT_CHANCE, FRIEND_BASE_ACCEPT_CHANCE + float(get_controlled_count()) * FRIEND_ACCEPT_BARRIO_BONUS)


func can_invite_friend() -> bool:
	return get_friend_count() < get_friend_capacity()


func click_add_friend() -> Dictionary:
	if not can_invite_friend():
		var capped := {
			"accepted": false,
			"capped": true,
			"message": "Necesitás conquistar más territorios para sumar más amigos.",
		}
		friend_click_result.emit(capped)
		return capped

	friend_request_clicks += 1
	var required := get_friend_required_clicks()
	var result := {
		"accepted": false,
		"capped": false,
		"message": "Solicitud enviada...",
		"clicks": friend_request_clicks,
		"required": required,
	}

	if friend_request_clicks >= required:
		if randf() <= get_friend_accept_chance():
			var friend_id := _create_friend()
			friend_request_clicks = 0
			result["accepted"] = true
			result["friend_id"] = friend_id
			result["message"] = "%s aceptó tu solicitud." % get_companion_display_name(friend_id)
		else:
			friend_request_clicks = int(float(required) * 0.25)
			result["message"] = "No respondió. Conservás parte del progreso."
		result["clicks"] = friend_request_clicks

	save_game()
	friend_click_result.emit(result)
	return result


func _create_friend() -> String:
	_friend_seq += 1
	var id := "friend:%d" % _friend_seq
	var name := FRIEND_NAMES[randi() % FRIEND_NAMES.size()]
	var colors := ["#8FD3FF", "#F2B6FF", "#B8F28F", "#FFD08F", "#D6C7FF"]
	friends[id] = {
		"name": "%s #%d" % [name, _friend_seq],
		"base_health": randf_range(48.0, 66.0),
		"base_damage": randf_range(3.0, 5.0),
		"level": 1,
		"weapon": 0,
		"tint_html": colors[randi() % colors.size()],
	}
	return id


func get_friend_combat_def(friend_id: String) -> Dictionary:
	var row: Dictionary = friends.get(friend_id, {})
	var level := int(row.get("level", 1))
	var weapon := int(row.get("weapon", 0))
	var weapon_def: Dictionary = FRIEND_WEAPONS[clampi(weapon, 0, FRIEND_WEAPONS.size() - 1)]
	var tint := Color.from_string(str(row.get("tint_html", "#FFFFFF")), Color.WHITE)
	return {
		"id": friend_id,
		"display_name": str(row.get("name", "Amigo")),
		"max_health": float(row.get("base_health", 55.0)) + float(level - 1) * FRIEND_TRAIN_HP_PER_LEVEL,
		"damage": float(row.get("base_damage", 4.0)) + float(level - 1) * FRIEND_TRAIN_DMG_PER_LEVEL + float(weapon_def.get("damage_bonus", 0.0)),
		"follow_distance": 3.0,
		"tint": tint,
	}


func get_friend_train_cost(friend_id: String) -> int:
	var row: Dictionary = friends.get(friend_id, {})
	var level := int(row.get("level", 1))
	if level >= FRIEND_MAX_LEVEL:
		return -1
	return 140 + level * 110


func train_friend(friend_id: String) -> bool:
	if not friends.has(friend_id):
		return false
	var cost := get_friend_train_cost(friend_id)
	if cost < 0 or money < cost:
		return false
	friends[friend_id]["level"] = int(friends[friend_id].get("level", 1)) + 1
	money -= cost
	save_game()
	money_spent.emit(cost)
	return true


func get_friend_weapon_cost(friend_id: String) -> int:
	var row: Dictionary = friends.get(friend_id, {})
	var next_weapon := int(row.get("weapon", 0)) + 1
	if next_weapon >= FRIEND_WEAPONS.size():
		return -1
	return int(FRIEND_WEAPONS[next_weapon].get("cost", 0))


func buy_friend_weapon(friend_id: String) -> bool:
	if not friends.has(friend_id):
		return false
	var cost := get_friend_weapon_cost(friend_id)
	if cost < 0 or money < cost:
		return false
	friends[friend_id]["weapon"] = int(friends[friend_id].get("weapon", 0)) + 1
	money -= cost
	save_game()
	money_spent.emit(cost)
	return true
