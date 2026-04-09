class_name ShipLightingMechanic
extends MechanicBase

var world_env: WorldEnvironment


func _ready() -> void:
	world_env = get_parent()
	MechanicsManager.register("ship_lighting", self )
	FuelManager.ship_fuel_changed.connect(on_ship_fuel_changed)
	_apply(FuelManager.ship_fuel)


func on_ship_fuel_changed(_old: float, new_val: float) -> void:
	if not is_active:
		return
	_apply(new_val)


func _apply(fuel: float) -> void:
	world_env.environment.background_energy_multiplier = lerp(0.0, 1.0, fuel)
	world_env.environment.ambient_light_energy = lerp(0.0, 0.3, fuel)
