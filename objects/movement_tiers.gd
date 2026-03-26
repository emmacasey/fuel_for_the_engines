class_name MovementTiersMechanic
extends MechanicBase

# Set from get_parent() in _ready — this mechanic must be a child of the Player node.
var player: CharacterBody3D


func _ready() -> void:
	player = get_parent()
	MechanicsManager.register("movement_tiers", self)
	FuelManager.player_fuel_changed.connect(on_player_fuel_changed)
	# Apply immediately so tiers are correct from the first frame
	_apply_tiers(FuelManager.player_fuel)


func on_player_fuel_changed(_old: float, new_val: float) -> void:
	if not is_active:
		return
	_apply_tiers(new_val)


func _apply_tiers(fuel: float) -> void:
	if fuel > 0.5:
		player.movement_speed = 5
		player.jump_strength = 8
		player.sound_alarm.stream_paused = true
	elif fuel > 0.25:
		player.movement_speed = 5
		player.jump_strength = 4
		player.sound_alarm.stream_paused = true
	elif fuel > 0.1:
		player.movement_speed = 3
		player.jump_strength = 0
		player.sound_alarm.stream_paused = true
	else:
		player.movement_speed = 1
		player.jump_strength = 0
		player.sound_alarm.stream_paused = false
