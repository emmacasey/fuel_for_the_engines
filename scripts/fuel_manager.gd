extends Node

# Normalized fuel levels (0.0–1.0)
var player_fuel: float = 1.0
var ship_fuel: float = 1.0

# Passive drain rates (per second, normalized 0.0–1.0)
var ship_drain_rate: float = 0.0
var player_drain_rate: float = 0.0

# Fraction of current player fuel transferred per E press (0.1 = 10%).
@export var transfer_chunk: float = 0.1
# How much ship fuel a unit of player fuel buys. 1.0 = equal exchange.
# Lower values create the "ship is much bigger" feeling.
@export var transfer_multiplier: float = 1.0

# Parasite feedback: 600-frame ring buffer of normalized per-second feedback rates.
# Living enemies feed fuel back to the ship on a delay — killing them removes income.
var _lagged_values: Array = []
var _registered_enemies: Array = []

const THRESHOLDS: Dictionary = {
	"critical": 0.15,
	"low": 0.35,
	"medium": 0.55,
	"high": 0.75,
	"full": 0.95,
}

signal player_fuel_changed(old_value: float, new_value: float)
signal ship_fuel_changed(old_value: float, new_value: float)
# direction: 1 = crossed upward, -1 = crossed downward
signal player_fuel_crossed_threshold(threshold_name: String, direction: int)
signal ship_fuel_crossed_threshold(threshold_name: String, direction: int)


func _ready() -> void:
	_lagged_values.resize(600)
	_lagged_values.fill(0.0)
	# Initialize drain after all scene nodes (and their _ready calls) complete
	call_deferred("_initialize_drain")


func _initialize_drain() -> void:
	ship_drain_rate = 0.0
	for e in _registered_enemies:
		if is_instance_valid(e):
			ship_drain_rate += float(e.value) * 3.0 / 10000.0
	_lagged_values.fill(ship_drain_rate)


func _process(delta: float) -> void:
	# Current normalized per-second feedback from living parasites
	var current_feedback: float = 0.0
	for e in _registered_enemies:
		if is_instance_valid(e):
			current_feedback += float(e.value) / 10000.0

	# Advance the ring buffer: append now, pop 600 frames ago
	_lagged_values.append(current_feedback)
	var lagged_feedback: float = _lagged_values.pop_front()

	# Ship fuel: drain continuously, gain from lagged parasite feedback
	var old_ship := ship_fuel
	ship_fuel = clamp(ship_fuel - ship_drain_rate * delta + lagged_feedback * delta, 0.0, 1.0)
	if ship_fuel != old_ship:
		_check_thresholds(old_ship, ship_fuel, false)
		ship_fuel_changed.emit(old_ship, ship_fuel)

	# Player passive drain (0 by default; future mechanics can set this)
	if player_drain_rate > 0.0:
		var old_player := player_fuel
		player_fuel = clamp(player_fuel - player_drain_rate * delta, 0.0, 1.0)
		if player_fuel != old_player:
			_check_thresholds(old_player, player_fuel, true)
			player_fuel_changed.emit(old_player, player_fuel)


func register_enemy(enemy: Node3D) -> void:
	if enemy not in _registered_enemies:
		_registered_enemies.append(enemy)


# Returns false if insufficient fuel (fuel unchanged)
func drain_player(amount: float) -> bool:
	if player_fuel < amount:
		return false
	_set_player_fuel(player_fuel - amount)
	return true


# Force-drain player fuel regardless of amount (clamps to 0); use for incoming damage
func damage_player(amount: float) -> void:
	_set_player_fuel(player_fuel - amount)


func add_player(amount: float) -> void:
	_set_player_fuel(player_fuel + amount)


func drain_ship(amount: float) -> void:
	_set_ship_fuel(ship_fuel - amount)


func add_ship(amount: float) -> void:
	_set_ship_fuel(ship_fuel + amount)


# Transfer player fuel to the ship. Ship gain = player_amount * transfer_multiplier.
func transfer_to_ship(player_amount: float) -> void:
	if drain_player(player_amount):
		add_ship(player_amount * transfer_multiplier)


func _set_player_fuel(new_val: float) -> void:
	var old_val := player_fuel
	player_fuel = clamp(new_val, 0.0, 1.0)
	if player_fuel != old_val:
		_check_thresholds(old_val, player_fuel, true)
		player_fuel_changed.emit(old_val, player_fuel)


func _set_ship_fuel(new_val: float) -> void:
	var old_val := ship_fuel
	ship_fuel = clamp(new_val, 0.0, 1.0)
	if ship_fuel != old_val:
		_check_thresholds(old_val, ship_fuel, false)
		ship_fuel_changed.emit(old_val, ship_fuel)


func _check_thresholds(old_val: float, new_val: float, is_player: bool) -> void:
	for threshold_name: String in THRESHOLDS:
		var t: float = THRESHOLDS[threshold_name]
		if old_val < t and new_val >= t:
			if is_player:
				player_fuel_crossed_threshold.emit(threshold_name, 1)
			else:
				ship_fuel_crossed_threshold.emit(threshold_name, 1)
		elif old_val >= t and new_val < t:
			if is_player:
				player_fuel_crossed_threshold.emit(threshold_name, -1)
			else:
				ship_fuel_crossed_threshold.emit(threshold_name, -1)
