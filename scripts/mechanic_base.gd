class_name MechanicBase
extends Node

var is_active: bool = true


func activate() -> void:
	is_active = true


func deactivate() -> void:
	is_active = false


func on_player_fuel_changed(_old: float, _new: float) -> void:
	pass


func on_ship_fuel_changed(_old: float, _new: float) -> void:
	pass
