extends Node2D
class_name CityMapAmbientLife

## Sprites animados del manifest ambient_sprites.json, colocados sobre el mapa estático.

const MANIFEST_PATH := "res://textures/map/city/ambient/shared/ambient_sprites.json"
const AMBIENT_BASE := "res://textures/map/city/ambient/"

var _manifest: Dictionary = {}
var _image_size := Vector2.ZERO


func _ready() -> void:
	_load_manifest()


func _load_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_warning("Ambient manifest no encontrado: %s" % MANIFEST_PATH)
		return
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_manifest = parsed
	else:
		push_warning("ambient_sprites.json inválido")


func apply_for_quadrant(quadrant_id: String, image_rect: Rect2) -> void:
	for child in get_children():
		child.queue_free()
	if image_rect.size.x < 1.0:
		return
	position = image_rect.position
	_image_size = image_rect.size
	if _manifest.is_empty():
		_load_manifest()
	for entry: Variant in _manifest.get("sprites", []):
		if not entry is Dictionary:
			continue
		var data: Dictionary = entry
		if str(data.get("quadrant", "")) != quadrant_id:
			continue
		match str(data.get("type", "")):
			"animated_sheet":
				_add_animated_sheet(data)
			"rotating_sprite":
				_add_rotating_sprite(data)
			_:
				pass


func _norm_to_local(norm: Vector2) -> Vector2:
	return Vector2(norm.x * _image_size.x, norm.y * _image_size.y)


func _vec2_from_array(arr: Variant, fallback: Vector2) -> Vector2:
	if arr is Array and arr.size() >= 2:
		return Vector2(float(arr[0]), float(arr[1]))
	return fallback


func _frame_size_from_entry(data: Dictionary) -> Vector2:
	var fs: Variant = data.get("frame_size", [64, 64])
	if fs is Array and fs.size() >= 2:
		return Vector2(float(fs[0]), float(fs[1]))
	return Vector2(64, 64)


func _texture_path(data: Dictionary) -> String:
	return AMBIENT_BASE + str(data.get("file", ""))


func _additive_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat


func _build_sprite_frames(tex: Texture2D, frame_size: Vector2, frame_count: int, fps: float) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"default")
	frames.set_animation_speed(&"default", fps)
	frames.set_animation_loop(&"default", true)
	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * frame_size.x, 0.0, frame_size.x, frame_size.y)
		frames.add_frame(&"default", atlas)
	return frames


func _apply_pivot(node: CanvasItem, frame_size: Vector2, pivot: Vector2) -> void:
	if node is Sprite2D:
		(node as Sprite2D).centered = false
		(node as Sprite2D).offset = -Vector2(frame_size.x * pivot.x, frame_size.y * pivot.y)
	elif node is AnimatedSprite2D:
		(node as AnimatedSprite2D).centered = false
		(node as AnimatedSprite2D).offset = -Vector2(frame_size.x * pivot.x, frame_size.y * pivot.y)


func _add_animated_sheet(data: Dictionary) -> void:
	var path: String = _texture_path(data)
	if not ResourceLoader.exists(path):
		push_warning("Sprite ambiental no encontrado: %s" % path)
		return
	var tex: Texture2D = load(path)
	if tex == null:
		return
	var frame_size: Vector2 = _frame_size_from_entry(data)
	var frame_count: int = int(data.get("frame_count", 1))
	var fps: float = float(data.get("fps", 8))
	var norm_pos: Vector2 = _vec2_from_array(data.get("position"), Vector2.ZERO)
	var pivot: Vector2 = _vec2_from_array(data.get("pivot"), Vector2(0.5, 0.5))

	var sprite := AnimatedSprite2D.new()
	sprite.name = str(data.get("id", "ambient"))
	sprite.sprite_frames = _build_sprite_frames(tex, frame_size, frame_count, fps)
	sprite.position = _norm_to_local(norm_pos)
	_apply_pivot(sprite, frame_size, pivot)
	sprite.material = _additive_material()
	sprite.animation = &"default"
	sprite.play()
	add_child(sprite)


func _add_rotating_sprite(data: Dictionary) -> void:
	var path: String = _texture_path(data)
	if not ResourceLoader.exists(path):
		push_warning("Sprite ambiental no encontrado: %s" % path)
		return
	var tex: Texture2D = load(path)
	if tex == null:
		return
	var frame_size: Vector2 = _frame_size_from_entry(data)
	var norm_pos: Vector2 = _vec2_from_array(data.get("position"), Vector2.ZERO)
	var pivot: Vector2 = _vec2_from_array(data.get("pivot"), Vector2(0.5, 0.5))
	var period: float = float(data.get("rotation_period_sec", 5.5))

	var rotator := Node2D.new()
	rotator.name = str(data.get("id", "rotating"))
	rotator.position = _norm_to_local(norm_pos)
	add_child(rotator)

	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.offset = -Vector2(frame_size.x * pivot.x, frame_size.y * pivot.y)
	sprite.material = _additive_material()
	rotator.add_child(sprite)

	var tween := create_tween().set_loops()
	tween.tween_property(rotator, "rotation", TAU, period).from(0.0)
