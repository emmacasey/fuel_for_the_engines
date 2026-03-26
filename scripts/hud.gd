extends CanvasLayer

var show_fuel := true


func _ready() -> void:
	FuelManager.player_fuel_changed.connect(_on_player_fuel_changed)
	FuelManager.ship_fuel_changed.connect(_on_ship_fuel_changed)


func _on_player_fuel_changed(_old: float, new_val: float) -> void:
	$Health.text = str(int(new_val * 100)) + "%"


func _on_ship_fuel_changed(_old: float, new_val: float) -> void:
	if show_fuel:
		$Fuel.text = str(int(new_val * 100))
	else:
		$Fuel.text = ""
