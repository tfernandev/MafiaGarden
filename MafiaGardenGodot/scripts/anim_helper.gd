class_name AnimHelper
extends RefCounted

const IDLE_KEYWORDS := ["idle", "idlesoldado", "idlechica"]
const WALK_KEYWORDS := ["walk", "walking", "run", "jog"]
const FIRE_KEYWORDS := ["fire", "firing", "rifle", "firigin", "shoot", "shot"]
const DEATH_KEYWORDS := ["death", "die", "dying", "dead"]


static func find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := find_animation_player(child)
		if found:
			return found
	return null


static func resolve_animation_name(player: AnimationPlayer, anim_name: String) -> String:
	if player == null or anim_name.is_empty():
		return ""
	var direct := str(anim_name)
	if player.has_animation(direct):
		return direct
	var with_lib := "default/%s" % direct
	if player.has_animation(with_lib):
		return with_lib
	for existing in player.get_animation_list():
		if existing.get_file() == direct:
			return existing
	return ""


static func play_first(
	player: AnimationPlayer,
	names: Array,
	blend: float = 0.15,
	speed: float = 1.0
) -> bool:
	if player == null:
		return false
	for anim_name in names:
		var resolved := resolve_animation_name(player, str(anim_name))
		if resolved.is_empty():
			continue
		if player.current_animation != resolved:
			player.play(resolved, blend)
		player.speed_scale = speed
		return true
	return false


static func play_by_keywords(
	player: AnimationPlayer,
	keywords: Array,
	blend: float = 0.15,
	speed: float = 1.0
) -> bool:
	if player == null:
		return false
	for anim_name in player.get_animation_list():
		var lower := anim_name.to_lower()
		if lower.contains("t-pose") or lower.contains("tpose"):
			continue
		for keyword in keywords:
			if str(keyword).to_lower() in lower:
				if player.current_animation != anim_name:
					player.play(anim_name, blend)
				player.speed_scale = speed
				return true
	return false


static func play_idle(player: AnimationPlayer, blend: float = 0.15) -> bool:
	return play_first(player, ["IdleSoldado", "Idlechica", "Idle"], blend) \
		or play_by_keywords(player, IDLE_KEYWORDS, blend)


static func play_walk(player: AnimationPlayer, blend: float = 0.15, speed: float = 1.0) -> bool:
	return play_first(player, ["WalkingSoldado", "Walkingchica", "Walking"], blend, speed) \
		or play_by_keywords(player, WALK_KEYWORDS, blend, speed)


## Anula solo X/Z del hueso Hips (root motion horizontal Mixamo); conserva Y para no hundir el mesh.
static func strip_hips_horizontal_root_motion(player: AnimationPlayer) -> int:
	if player == null:
		return 0
	var modified := 0
	for anim_name in player.get_animation_list():
		var anim := player.get_animation(anim_name)
		if anim == null:
			continue
		for i in range(anim.get_track_count()):
			if anim.track_get_type(i) != Animation.TYPE_POSITION_3D:
				continue
			if not _is_hips_position_path(str(anim.track_get_path(i))):
				continue
			var key_count := anim.track_get_key_count(i)
			if key_count == 0:
				continue
			var anchor: Vector3 = anim.track_get_key_value(i, 0)
			for k in range(key_count):
				var pos: Vector3 = anim.track_get_key_value(i, k)
				anim.track_set_key_value(i, k, Vector3(anchor.x, pos.y, anchor.z))
			modified += 1
	return modified


static func _is_hips_position_path(path: String) -> bool:
	var lower := path.to_lower()
	if "hips" in lower:
		return true
	if lower.ends_with("root") or ":root" in lower or "/root" in lower:
		return true
	return false


static func play_fire(player: AnimationPlayer, blend: float = 0.1) -> bool:
	return play_first(
		player,
		["FiringRifleSoldado", "FiringRiflechica", "FiriginRiflechica", "Firing Rifle"],
		blend
	) or play_by_keywords(player, FIRE_KEYWORDS, blend)


static func play_death(player: AnimationPlayer, blend: float = 0.1) -> bool:
	return play_first(player, ["DeathSoldado", "Deathchica", "Death"], blend) \
		or play_by_keywords(player, DEATH_KEYWORDS, blend)
