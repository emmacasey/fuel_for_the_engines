class_name PlayerAlarmMechanic
extends MechanicBase

var player: CharacterBody3D

const ALARM_THRESHOLD := 0.1


func _ready() -> void:
	player = get_parent()
	MechanicsManager.register("player_alarm", self)
	FuelManager.player_fuel_changed.connect(on_player_fuel_changed)
	_apply(FuelManager.player_fuel)


func on_player_fuel_changed(_old: float, new_val: float) -> void:
	if not is_active:
		return
	_apply(new_val)


func _apply(fuel: float) -> void:
	player.sound_alarm.stream_paused = fuel > ALARM_THRESHOLD
