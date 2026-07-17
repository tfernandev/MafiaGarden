extends RefCounted
class_name MapSpawnUtil

const MIN_PLAYER_DISTANCE := 11.0
const MIN_PLAYER_Z_GAP := 12.0


static func pick_spawn_points(
	candidates: Array[Vector3],
	count: int,
	player: Node3D
) -> Array[Vector3]:
	var pool: Array[Vector3] = []
	for p in candidates:
		if _is_safe_for_player(p, player):
			pool.append(p)
	pool.shuffle()
	var result: Array[Vector3] = []
	for i in count:
		if i < pool.size():
			result.append(pool[i])
		elif not candidates.is_empty():
			result.append(_push_away_from_player(candidates[i % candidates.size()], player))
	return result


static func _is_safe_for_player(pos: Vector3, player: Node3D) -> bool:
	if player == null:
		return true
	var player_pos := player.global_position
	if pos.z - player_pos.z < MIN_PLAYER_Z_GAP:
		return false
	return player_pos.distance_to(pos) >= MIN_PLAYER_DISTANCE


static func _push_away_from_player(pos: Vector3, player: Node3D) -> Vector3:
	if player == null:
		return pos
	var player_pos := player.global_position
	var out := pos
	if out.z - player_pos.z < MIN_PLAYER_Z_GAP:
		out.z = player_pos.z + MIN_PLAYER_Z_GAP
	if player_pos.distance_to(out) < MIN_PLAYER_DISTANCE:
		out = player_pos + Vector3(0.0, 0.0, MIN_PLAYER_Z_GAP)
	return out
