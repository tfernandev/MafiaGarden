@tool
extends EditorPlugin
## Addon Prop Attach — menú Editor + runners headless vía MCP.

const InspectScript := preload("res://addons/prop_attach/prop_attach_skeleton_inspect.gd")


func _enter_tree() -> void:
	add_tool_menu_item("Prop Attach: Inspect Skeleton (selected)", _on_inspect_selected)


func _exit_tree() -> void:
	remove_tool_menu_item("Prop Attach: Inspect Skeleton (selected)")


func _on_inspect_selected() -> void:
	var sel := get_editor_interface().get_selection().get_selected_nodes()
	if sel.is_empty():
		push_warning("PropAttach: seleccioná un nodo con Skeleton3D.")
		return
	var skeleton: Skeleton3D = InspectScript.find_skeleton(sel[0])
	if skeleton == null:
		push_warning("PropAttach: no hay Skeleton3D bajo el nodo seleccionado.")
		return
	var report: Dictionary = InspectScript.inspect(skeleton)
	print("[PropAttach] bones=%d hands=%s" % [
		report.get("bone_count", 0),
		str(report.get("hand_bones", {}))
	])
	var path := "user://prop_attach_inspect.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(report, "\t"))
		f.close()
		print("[PropAttach] wrote %s" % ProjectSettings.globalize_path(path))
