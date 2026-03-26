extends Node

# Registry of mechanics by name. Each value is a MechanicBase node.
var _mechanics: Dictionary = {}


func register(mechanic_name: String, mechanic: Node) -> void:
	_mechanics[mechanic_name] = mechanic


func set_active(mechanic_name: String, active: bool) -> void:
	if not _mechanics.has(mechanic_name):
		return
	if active:
		_mechanics[mechanic_name].activate()
	else:
		_mechanics[mechanic_name].deactivate()


func is_active(mechanic_name: String) -> bool:
	if not _mechanics.has(mechanic_name):
		return false
	return _mechanics[mechanic_name].is_active


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	# F1: list mechanics and their current state
	if event.physical_keycode == KEY_F1:
		_print_debug()
		return
	# F2–F9: toggle mechanics in registration order
	var toggle_keys := [KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9]
	var names := _mechanics.keys()
	for i in toggle_keys.size():
		if event.physical_keycode == toggle_keys[i] and i < names.size():
			set_active(names[i], not is_active(names[i]))
			print("MechanicsManager: '%s' → %s" % [names[i], "ON" if is_active(names[i]) else "OFF"])


func _print_debug() -> void:
	print("=== MechanicsManager ===")
	var names := _mechanics.keys()
	for i in names.size():
		print("  [F%d] %s: %s" % [i + 2, names[i], "ON" if is_active(names[i]) else "OFF"])
	print("========================")
