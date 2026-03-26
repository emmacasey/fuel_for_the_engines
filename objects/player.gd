extends CharacterBody3D

@export_subgroup("Properties")
@export var movement_speed = 5
@export var jump_strength = 8

@export_subgroup("Weapons")
@export var weapons: Array[Weapon] = []

var weapon: Weapon
var weapon_index := 0

var mouse_sensitivity = 700
var gamepad_sensitivity := 0.075

var mouse_captured := true

var movement_velocity: Vector3
var rotation_target: Vector3

var input_mouse: Vector2

var gravity := 0.0

var previously_floored := false

var jump_single := true
var jump_double := true

var container_offset = Vector3(1.2, -1.1, -2.75)

var tween: Tween

@onready var camera = $Head/Camera
@onready var raycast = $Head/Camera/RayCast
@onready var muzzle = $Head/Camera/SubViewportContainer/SubViewport/CameraItem/Muzzle
@onready var container = $Head/Camera/SubViewportContainer/SubViewport/CameraItem/Container
@onready var sound_footsteps = $SoundFootsteps
@onready var sound_alarm = $AlarmSound
@onready var blaster_cooldown = $Cooldown

@export var crosshair: TextureRect


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	weapon = weapons[weapon_index]
	initiate_change_weapon(weapon_index)

	var tiers = preload("res://objects/movement_tiers.gd").new()
	add_child(tiers)


func _physics_process(delta: float) -> void:
	handle_controls(delta)
	handle_gravity(delta)

	var applied_velocity: Vector3

	movement_velocity = transform.basis * movement_velocity

	applied_velocity = velocity.lerp(movement_velocity, delta * 10)
	applied_velocity.y = -gravity

	velocity = applied_velocity
	move_and_slide()

	camera.rotation.z = lerp_angle(camera.rotation.z, -input_mouse.x * 25 * delta, delta * 5)

	camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, delta * 25)
	rotation.y = lerp_angle(rotation.y, rotation_target.y, delta * 25)

	container.position = lerp(container.position, container_offset - (applied_velocity / 30), delta * 10)

	sound_footsteps.stream_paused = true

	if is_on_floor():
		if abs(velocity.x) > 1 or abs(velocity.z) > 1:
			sound_footsteps.stream_paused = false

	camera.position.y = lerp(camera.position.y, 0.0, delta * 5)

	if is_on_floor() and gravity > 1 and !previously_floored:
		Audio.play("assets/sounds/land.ogg")
		camera.position.y = -0.1

	previously_floored = is_on_floor()

	if position.y < -10:
		die()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured:
		input_mouse = event.relative / mouse_sensitivity
		rotation_target.y -= event.relative.x / mouse_sensitivity
		rotation_target.x -= event.relative.y / mouse_sensitivity


func handle_controls(_delta: float) -> void:
	if Input.is_action_just_pressed("mouse_capture"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured = true

	if Input.is_action_just_pressed("mouse_capture_exit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_captured = false
		input_mouse = Vector2.ZERO

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	movement_velocity = Vector3(input.x, 0, input.y).normalized() * movement_speed

	var rotation_input := Input.get_vector("camera_right", "camera_left", "camera_down", "camera_up")
	rotation_target -= Vector3(-rotation_input.y, -rotation_input.x, 0).limit_length(1.0) * gamepad_sensitivity
	rotation_target.x = clamp(rotation_target.x, deg_to_rad(-90), deg_to_rad(90))

	if Input.is_action_just_pressed("shoot"):
		action_shoot()

	if Input.is_action_just_pressed("jump"):
		action_jump()

	if Input.is_action_just_pressed("weapon_toggle"):
		action_weapon_toggle()

	if Input.is_action_just_pressed("fuel_engine"):
		action_fuel_engine()


func handle_gravity(delta: float) -> void:
	gravity += 20 * delta
	if gravity > 0 and is_on_floor():
		jump_single = true
		gravity = 0


func action_jump() -> void:
	if jump_single or jump_double:
		if jump_double and FuelManager.player_fuel > 0.5 and FuelManager.drain_player(0.05):
			jump_double = false
		elif jump_single and FuelManager.drain_player(0.01):
			jump_single = false
			jump_double = true
		else:
			return

		Audio.play("assets/sounds/jump_a.ogg, sounds/jump_b.ogg, sounds/jump_c.ogg")
		gravity = -jump_strength


func action_shoot() -> void:
	if !blaster_cooldown.is_stopped():
		return

	if FuelManager.drain_player(float(weapon.shot_count) / 100.0):
		Audio.play(weapon.sound_shoot)

		container.position.z += 0.25
		camera.rotation.x += 0.025
		movement_velocity += Vector3(0, 0, weapon.knockback)

		muzzle.play("default")
		muzzle.rotation_degrees.z = randf_range(-45, 45)
		muzzle.scale = Vector3.ONE * randf_range(0.40, 0.75)
		muzzle.position = container.position - weapon.muzzle_position

		blaster_cooldown.start(weapon.cooldown)

		for n in weapon.shot_count:
			raycast.target_position.x = randf_range(-weapon.spread, weapon.spread)
			raycast.target_position.y = randf_range(-weapon.spread, weapon.spread)

			raycast.force_raycast_update()

			if !raycast.is_colliding():
				continue

			var collider = raycast.get_collider()

			if collider.has_method("damage"):
				collider.damage(weapon.damage)

			var impact = preload("res://objects/impact.tscn")
			var impact_instance = impact.instantiate()

			impact_instance.play("shot")

			get_tree().root.add_child(impact_instance)

			impact_instance.position = raycast.get_collision_point() + (raycast.get_collision_normal() / 10)
			impact_instance.look_at(camera.global_transform.origin, Vector3.UP, true)
	else:
		pass # misfire sound


func action_weapon_toggle() -> void:
	weapon_index = wrap(weapon_index + 1, 0, weapons.size())
	initiate_change_weapon(weapon_index)
	Audio.play("assets/sounds/weapon_change.ogg")


func initiate_change_weapon(index: int) -> void:
	weapon_index = index

	tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(container, "position", container_offset - Vector3(0, 1, 0), 0.1)
	tween.tween_callback(change_weapon)


func change_weapon() -> void:
	weapon = weapons[weapon_index]

	for n in container.get_children():
		container.remove_child(n)

	var weapon_model = weapon.model.instantiate()
	container.add_child(weapon_model)

	weapon_model.position = weapon.position
	weapon_model.rotation_degrees = weapon.rotation

	for child in weapon_model.find_children("*", "MeshInstance3D"):
		child.layers = 2

	raycast.target_position = Vector3(0, 0, -1) * weapon.max_distance
	crosshair.texture = weapon.crosshair


func damage(amount: int) -> void:
	FuelManager.damage_player(float(amount) / 100.0)
	if FuelManager.player_fuel <= 0.0:
		die()


func action_fuel_engine() -> void:
	FuelManager.transfer_to_ship(FuelManager.player_fuel * 0.1)


func die() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/title.tscn")
