extends SceneTree
## Runner genérico Prop Attach.
## godot --path <project> --headless --script res://addons/prop_attach/prop_attach_runner.gd -- \
##   --character=res://character.tscn --prop=res://prop.tscn --anim=Idle [--inspect-only]

const AgentScript := preload("res://addons/prop_attach/prop_attach_agent.gd")


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var cfg: Dictionary = AgentScript.parse_cmdline()
	var agent: Node = AgentScript.new()
	root.add_child(agent)
	var report: Dictionary = await agent.run(cfg)
	var code := 0 if report.get("pass", false) else 1
	quit(code)
