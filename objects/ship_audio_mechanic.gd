class_name ShipAudioMechanic
extends MechanicBase

var sound_happy: AudioStreamPlayer
var sound_alarm: AudioStreamPlayer
var sound_spooky: AudioStreamPlayer


func _ready() -> void:
	var parent = get_parent()
	sound_happy = parent.get_node("HappyMusic")
	sound_alarm = parent.get_node("AlarmSound")
	sound_spooky = parent.get_node("SpookyMusic")
	MechanicsManager.register("ship_audio", self )
	FuelManager.ship_fuel_changed.connect(on_ship_fuel_changed)
	_apply(FuelManager.ship_fuel)


func on_ship_fuel_changed(_old: float, new_val: float) -> void:
	if not is_active:
		return
	_apply(new_val)


func _apply(fuel: float) -> void:
	sound_happy.volume_db = lerp(-80.0, 0.0, clamp((fuel - 0.6) / 0.4, 0.0, 1.0))
	sound_alarm.volume_db = lerp(0.0, -80.0, clamp(fuel / 0.3, 0.0, 1.0))
	sound_spooky.volume_db = lerp(0.0, -80.0, fuel)
