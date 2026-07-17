extends Node
class_name WaveManager

signal wave_started(wave_number: int, enemy_count: int)
signal wave_cleared(wave_number: int)
signal all_waves_cleared
signal enemy_count_changed(alive_count: int)

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

@export var wave_counts: Array[int] = [1, 2, 2]
@export var wave_delays: Array[float] = [0.5, 2.5, 3.0]
@export var between_wave_delay := 2.0

var _enemies_root: Node3D
var _map: Node3D
var _wave_index := -1
var _alive_this_wave := 0
var _running := false
var _enemy_pool: Array[String] = ["thug"]


func setup(enemies_root: Node3D, map: Node3D = null) -> void:
	_enemies_root = enemies_root
	_map = map


func configure_from_barrio(barrio: BarrioData) -> void:
	if barrio == null:
		return
	wave_counts = barrio.wave_counts.duplicate()
	wave_delays = barrio.wave_delays.duplicate()
	_enemy_pool.clear()
	for id in barrio.enemy_pool:
		_enemy_pool.append(str(id))
	if _enemy_pool.is_empty():
		_enemy_pool.append("thug")


func start() -> void:
	if _running or _enemies_root == null:
		return
	_running = true
	_wave_index = -1
	_advance_wave()


func get_total_waves() -> int:
	return wave_counts.size()


func get_display_wave() -> int:
	return clampi(_wave_index + 1, 1, get_total_waves())


func get_alive_enemy_count() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		if node.has_method("is_alive") and node.is_alive():
			count += 1
	return count


func _advance_wave() -> void:
	_wave_index += 1
	if _wave_index >= wave_counts.size():
		_running = false
		all_waves_cleared.emit()
		return

	var delay := between_wave_delay
	if _wave_index < wave_delays.size():
		delay = wave_delays[_wave_index]

	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	if not _running:
		return

	var count := wave_counts[_wave_index]
	_alive_this_wave = count
	wave_started.emit(_wave_index + 1, count)
	CombatAudio.play("wave")
	_spawn_wave_enemies(count)


func _spawn_wave_enemies(count: int) -> void:
	var candidates: Array[Vector3] = (
		_map.get_enemy_spawn_points() if _map and _map.has_method("get_enemy_spawn_points")
		else _fallback_spawn_points()
	)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var points := MapSpawnUtil.pick_spawn_points(candidates, count, player)
	for i in count:
		var enemy_id := EnemyCatalog.pick_for_wave(_enemy_pool, _wave_index, i)
		var enemy := ENEMY_SCENE.instantiate() as CharacterBody3D
		EnemyCatalog.apply(enemy, enemy_id)
		_apply_wave_scaling(enemy, _wave_index)
		_enemies_root.add_child(enemy)
		enemy.global_position = points[i]
		enemy.died.connect(_on_enemy_died)
		enemy.health_changed.connect(_on_enemy_health_changed)
	enemy_count_changed.emit(get_alive_enemy_count())


func _apply_wave_scaling(enemy: CharacterBody3D, wave_idx: int) -> void:
	if wave_idx <= 0:
		return
	var hp_mul := 1.0 + 0.08 * float(wave_idx)
	var dmg_mul := 1.0 + 0.06 * float(wave_idx)
	enemy.max_health = enemy.max_health * hp_mul
	enemy.health = enemy.max_health
	enemy.damage = enemy.damage * dmg_mul
	if wave_idx >= 2:
		enemy.fire_interval_min = maxf(0.28, enemy.fire_interval_min * 0.9)
		enemy.fire_interval_max = maxf(0.5, enemy.fire_interval_max * 0.9)


func _on_enemy_health_changed(_current: float, _maximum: float) -> void:
	enemy_count_changed.emit(get_alive_enemy_count())


func _fallback_spawn_points() -> Array[Vector3]:
	return [
		Vector3(-7.0, 0.0, 24.0),
		Vector3(7.0, 0.0, 24.0),
		Vector3(-7.0, 0.0, 18.0),
		Vector3(7.0, 0.0, 18.0),
	]


func _on_enemy_died() -> void:
	CombatAudio.play("enemy_death")
	_alive_this_wave = maxi(_alive_this_wave - 1, 0)
	enemy_count_changed.emit(get_alive_enemy_count())
	if _alive_this_wave > 0:
		return
	wave_cleared.emit(_wave_index + 1)
	if _wave_index + 1 >= wave_counts.size():
		_running = false
		all_waves_cleared.emit()
		return
	_advance_wave()
