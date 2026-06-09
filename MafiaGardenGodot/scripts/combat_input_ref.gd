extends RefCounted
class_name CombatInputRef

## Acceso al autoload sin depender del identificador global CombatInput (evita errores de compilación en export).


static func instance() -> CombatInputService:
	var tree := Engine.get_main_loop()
	if tree == null:
		return null
	return tree.root.get_node_or_null("CombatInput") as CombatInputService
