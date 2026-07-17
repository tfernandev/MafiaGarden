extends RefCounted
class_name MapProps

## Coloca props GLB/GLTF bajo DesignRoot si el archivo existe.

const PROP_DIR := "res://models/props/"

static func place_preset(parent: Node3D, preset: String) -> int:
	return place_layout(parent, _layout_for_preset(preset))


static func place_defaults(parent: Node3D) -> int:
	return place_layout(parent, _default_layout())


static func place_layout(parent: Node3D, layout: Array[Dictionary]) -> int:
	var placed := 0
	for entry in layout:
		var path: String = _resolve_prop_path(entry.path)
		if path.is_empty():
			continue
		var prop := PropStatic.new()
		prop.name = entry.name
		prop.model_path = path
		prop.collision_mode = entry.get("collision", PropStatic.CollisionMode.CONVEX)
		prop.model_rotation_degrees = entry.get("rotation", Vector3.ZERO)
		prop.model_scale = entry.get("scale", Vector3.ONE)
		prop.position = entry.pos
		if entry.has("yaw"):
			prop.rotation.y = entry.yaw
		parent.add_child(prop)
		placed += 1
	if placed > 0:
		print("[MapProps] Props colocados: ", placed)
	else:
		print("[MapProps] Sin modelos en models/props/ — ver models/props/README.md")
	return placed


static func _layout_for_preset(preset: String) -> Array[Dictionary]:
	match preset:
		"market":
			return _default_layout()
		"dense":
			var layout := _default_layout()
			layout.append({
				"name": "Barrel_B",
				"path": "Barrel_01",
				"pos": Vector3(3.5, 0.0, 16.0),
			})
			layout.append({
				"name": "Crate_Alley",
				"path": "wooden_crate_02",
				"pos": Vector3(-6.8, 0.0, 17.5),
				"yaw": 0.6,
			})
			return layout
		"port":
			return [
				{
					"name": "Crate_Port_A",
					"path": "wooden_crate_01",
					"pos": Vector3(-3.0, 0.0, 12.0),
					"yaw": 0.2,
				},
				{
					"name": "Crate_Port_B",
					"path": "wooden_crate_02",
					"pos": Vector3(3.2, 0.0, 14.0),
					"yaw": -0.3,
				},
				{
					"name": "Barrel_Port",
					"path": "Barrel_01",
					"pos": Vector3(-2.0, 0.0, 22.0),
				},
				{
					"name": "TrashCan_Port",
					"path": "metal_trash_can",
					"pos": Vector3(6.5, 0.0, 20.0),
					"yaw": 0.5,
				},
				{
					"name": "Lamp_Port",
					"path": "street_lamp_01",
					"pos": Vector3(-6.5, 0.0, 18.0),
				},
			]
		"old_town":
			return [
				{
					"name": "Bench_Old",
					"path": "painted_wooden_bench",
					"pos": Vector3(-6.8, 0.0, 11.0),
					"yaw": PI * 0.5,
				},
				{
					"name": "Crate_Old",
					"path": "wooden_crate_01",
					"pos": Vector3(2.0, 0.0, 13.0),
					"yaw": 0.4,
				},
				{
					"name": "Lamp_Old_1",
					"path": "street_lamp_01",
					"pos": Vector3(-6.5, 0.0, 19.0),
				},
				{
					"name": "Lamp_Old_2",
					"path": "street_lamp_01",
					"pos": Vector3(6.5, 0.0, 24.0),
				},
			]
		_:
			return _default_layout()


static func _resolve_prop_path(stem: String) -> String:
	var glb := "%s%s.glb" % [PROP_DIR, stem]
	if ResourceLoader.exists(glb):
		return glb
	var gltf := "%s%s_2k/%s_2k.gltf" % [PROP_DIR, stem, stem]
	if ResourceLoader.exists(gltf):
		return gltf
	return ""


static func _default_layout() -> Array[Dictionary]:
	return [
		{
			"name": "Crate_A",
			"path": "wooden_crate_01",
			"pos": Vector3(-2.0, 0.0, 8.0),
			"yaw": 0.3,
		},
		{
			"name": "Crate_B",
			"path": "wooden_crate_02",
			"pos": Vector3(2.4, 0.0, 10.5),
			"yaw": -0.5,
		},
		{
			"name": "Crate_C",
			"path": "wooden_crate_01",
			"pos": Vector3(-1.0, 0.0, 15.0),
			"yaw": 0.15,
		},
		{
			"name": "Crate_D",
			"path": "wooden_crate_02",
			"pos": Vector3(1.8, 0.0, 18.5),
			"yaw": 0.8,
		},
		{
			"name": "Barrel_A",
			"path": "Barrel_01",
			"pos": Vector3(-6.5, 0.0, 25.0),
		},
		{
			"name": "TrashCan_L",
			"path": "metal_trash_can",
			"pos": Vector3(-7.2, 0.0, 20.5),
			"yaw": 0.4,
		},
		{
			"name": "TrashCan_R",
			"path": "metal_trash_can",
			"pos": Vector3(7.0, 0.0, 23.5),
			"yaw": -0.6,
		},
		{
			"name": "Bench_L",
			"path": "painted_wooden_bench",
			"pos": Vector3(-6.8, 0.0, 9.5),
			"yaw": PI * 0.5,
		},
		{
			"name": "Lamp_1",
			"path": "street_lamp_01",
			"pos": Vector3(-6.5, 0.0, 7.0),
		},
		{
			"name": "Lamp_2",
			"path": "street_lamp_01",
			"pos": Vector3(6.5, 0.0, 13.0),
		},
		{
			"name": "Lamp_3",
			"path": "street_lamp_01",
			"pos": Vector3(-6.5, 0.0, 22.0),
		},
		{
			"name": "Lamp_4",
			"path": "street_lamp_01",
			"pos": Vector3(6.5, 0.0, 28.0),
		},
		{
			"name": "Sign_A",
			"path": "WetFloorSign_01",
			"pos": Vector3(6.8, 0.0, 8.5),
			"yaw": -0.3,
		},
	]
