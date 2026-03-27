class_name JumpMechanic
extends MechanicBase

var player: CharacterBody3D

var jump_single := true
var jump_double := true

const DOUBLE_JUMP_FUEL_THRESHOLD := 0.5
const DOUBLE_JUMP_COST := 0.05
const SINGLE_JUMP_COST := 0.01


func _ready() -> void:
	player = get_parent()
	MechanicsManager.register("jump", self)


func try_jump() -> void:
	if not is_active:
		return
	if not (jump_single or jump_double):
		return
	if jump_double and FuelManager.player_fuel > DOUBLE_JUMP_FUEL_THRESHOLD and FuelManager.drain_player(DOUBLE_JUMP_COST):
		jump_double = false
	elif jump_single and FuelManager.drain_player(SINGLE_JUMP_COST):
		jump_single = false
		jump_double = true
	else:
		return

	Audio.play("assets/sounds/jump_a.ogg, sounds/jump_b.ogg, sounds/jump_c.ogg")
	player.gravity = -player.jump_strength


# Called by player when it detects landing; always resets regardless of is_active
# so jump state is clean when the mechanic is re-enabled.
func on_landed() -> void:
	jump_single = true
