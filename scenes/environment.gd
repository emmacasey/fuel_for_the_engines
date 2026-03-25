extends WorldEnvironment

@onready
var enemies = get_node("../Enemies").find_children("enemy")
@onready var sound_happy = $HappyMusic
@onready var sound_spooky = $SpookyMusic
@onready var sound_alarm = $AlarmSound
var drain:float = 0
var fuel:float = 10000
var lagged_values:Array =[]
var ratio: int = 100

signal update_fuel 

# Called when the node enters the scene tree for the first time.
func _ready():
	for e in enemies:
		if e!=null:
			drain+=e.value*3
	lagged_values.resize(600)
	lagged_values.fill(drain)

	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	fuel-=drain*delta
	var current_value=0
	for e in enemies:
		if e!=null:
			current_value+=(e.value)
	lagged_values.append(current_value)
	fuel+=lagged_values.pop_front()*delta
	update_fuel.emit(int(fuel/ratio))

	if fuel > 9500:
		environment.background_energy_multiplier = 1
	elif fuel > 9000:
		environment.background_energy_multiplier = 0.1
	else:
		environment.background_energy_multiplier = 0

	if fuel > 8500:
		environment.ambient_light_energy = 0.3
	elif fuel > 8000:
		environment.ambient_light_energy = 0.15
	else:
		environment.ambient_light_energy = 0

	sound_happy.stream_paused = fuel < 8000
	sound_alarm.stream_paused = fuel > 2000
	sound_spooky.volume_db = -fuel/ratio

func fuel_engine(amount):
	fuel+=amount*ratio
