extends Node3D

@export var player: Node3D
@export var value: int

@onready var raycast = $RayCast
@onready var muzzle_a = $MuzzleA
@onready var muzzle_b = $MuzzleB

var health := 100
var time := 0.0
var target_position: Vector3
var destroyed := false

signal enemy_destroyed(value: int)


func _ready() -> void:
	target_position = position
	FuelManager.register_enemy(self)


func _process(delta: float) -> void:
	self.look_at(player.position + Vector3(0, 0.5, 0), Vector3.UP, true)
	target_position.y += (cos(time * 5) * 1) * delta
	time += delta
	position = target_position


func damage(amount: int) -> void:
	Audio.play("assets/sounds/enemy_hurt.ogg")
	health -= amount
	if health <= 0 and !destroyed:
		destroy()


func destroy() -> void:
	Audio.play("assets/sounds/enemy_destroy.ogg")
	FuelManager.add_player(float(value) / 100.0)
	enemy_destroyed.emit(value)
	destroyed = true
	queue_free()


func _on_timer_timeout() -> void:
	raycast.force_raycast_update()

	if raycast.is_colliding():
		var collider = raycast.get_collider()

		if collider.has_method("damage"):
			muzzle_a.frame = 0
			muzzle_a.play("default")
			muzzle_a.rotation_degrees.z = randf_range(-45, 45)

			muzzle_b.frame = 0
			muzzle_b.play("default")
			muzzle_b.rotation_degrees.z = randf_range(-45, 45)

			Audio.play("assets/sounds/enemy_attack.ogg")
			collider.damage(5)
