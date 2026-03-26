extends WorldEnvironment

@onready var sound_happy = $HappyMusic
@onready var sound_spooky = $SpookyMusic
@onready var sound_alarm = $AlarmSound


func _ready() -> void:
	FuelManager.ship_fuel_changed.connect(_on_ship_fuel_changed)
	# Sync atmosphere to whatever the initial fuel level is
	_on_ship_fuel_changed(FuelManager.ship_fuel, FuelManager.ship_fuel)


func _on_ship_fuel_changed(_old: float, new_val: float) -> void:
	var fuel := new_val

	# Lighting: smooth lerp across full fuel range
	environment.background_energy_multiplier = lerp(0.0, 1.0, fuel)
	environment.ambient_light_energy = lerp(0.0, 0.3, fuel)

	# Happy music: fades in above 60% fuel
	sound_happy.volume_db = lerp(-80.0, 0.0, clamp((fuel - 0.6) / 0.4, 0.0, 1.0))
	# Alarm: loud below 20% fuel, silent above 30%
	sound_alarm.volume_db = lerp(0.0, -80.0, clamp(fuel / 0.3, 0.0, 1.0))
	# Spooky ambience: loudest at zero fuel, silent at full
	sound_spooky.volume_db = lerp(0.0, -80.0, fuel)
