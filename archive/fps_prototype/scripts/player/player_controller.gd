class_name PlayerController
extends CharacterBody3D

signal player_health_changed(current_health: float, max_health: float)
signal player_ammo_changed(current_ammo: int, reserve_ammo: int)
signal player_died

# Movement Parameters
@export var walk_speed: float = 4.8
@export var sprint_speed: float = 7.5
@export var acceleration: float = 12.0
@export var friction: float = 10.0
@export var jump_velocity: float = 5.2
@export var mouse_sensitivity: float = 0.0025
@export var team_id: int = 2 # PDF

# Camera & Recoil
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var weapon_rig: Node3D = $Head/Camera3D/WeaponRig
@onready var weapon_manager: WeaponManager = $Head/Camera3D/WeaponRig/WeaponManager
@onready var health_component: HealthComponent = $HealthComponent
@onready var hitbox_component: HitboxComponent = $HitboxComponent

# ADS Parameters
var default_fov: float = 75.0
var ads_fov: float = 55.0
var is_aiming: bool = false
var ads_transition_speed: float = 12.0

# Procedural Head Bob & Sway
var bob_frequency: float = 2.4
var bob_amplitude: float = 0.04
var bob_timer: float = 0.0
var default_weapon_pos: Vector3 = Vector3(0.24, -0.22, -0.45)
var ads_weapon_pos: Vector3 = Vector3(0.0, -0.16, -0.35)

var gravity: float = 15.0
var is_active: bool = true

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if health_component:
		health_component.team_id = team_id
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)
		player_health_changed.emit(health_component.current_health, health_component.max_health)

	if hitbox_component:
		hitbox_component.team_id = team_id
		hitbox_component.health_component = health_component

	if weapon_manager:
		weapon_manager.camera = camera
		weapon_manager.team_id = team_id
		weapon_manager.ammo_changed.connect(_on_ammo_changed)
		player_ammo_changed.emit(weapon_manager.current_ammo, weapon_manager.reserve_ammo)

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return

	# Pointer lock capture on click
	if event is InputEventMouseButton and event.is_pressed():
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Mouse look rotation
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-88), deg_to_rad(88))

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get WASD input direction relative to player facing
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Determine speed (sprint vs walk)
	var is_sprinting = Input.is_action_pressed("sprint") and input_dir.y < 0 and is_on_floor()
	var target_speed = sprint_speed if is_sprinting else walk_speed

	# Accelerate / Decelerate
	if direction.length_squared() > 0.001:
		velocity.x = lerp(velocity.x, direction.x * target_speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * target_speed, acceleration * delta)
		# Accumulate head bob
		bob_timer += delta * (target_speed * 1.5)
	else:
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.z = lerp(velocity.z, 0.0, friction * delta)
		bob_timer = 0.0

	move_and_slide()

	# Handle ADS (Aim Down Sights)
	is_aiming = Input.is_action_pressed("aim_down_sights")
	var target_fov = ads_fov if is_aiming else default_fov
	camera.fov = lerp(camera.fov, target_fov, ads_transition_speed * delta)

	# Procedural weapon bobbing and positioning
	var target_weapon_pos = ads_weapon_pos if is_aiming else default_weapon_pos
	if is_on_floor() and direction.length_squared() > 0.01 and not is_aiming:
		var bob_offset = Vector3(
			sin(bob_timer * bob_frequency * 0.5) * bob_amplitude * 0.5,
			abs(sin(bob_timer * bob_frequency)) * bob_amplitude,
			0.0
		)
		weapon_rig.position = lerp(weapon_rig.position, target_weapon_pos + bob_offset, 12.0 * delta)
	else:
		weapon_rig.position = lerp(weapon_rig.position, target_weapon_pos, 12.0 * delta)

	# Shooting
	if Input.is_action_pressed("fire") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if weapon_manager and weapon_manager.can_shoot():
			weapon_manager.shoot()
			# Apply recoil pitch to head
			head.rotation.x = clamp(head.rotation.x + weapon_manager.recoil_pitch, deg_to_rad(-88), deg_to_rad(88))

	# Reloading
	if Input.is_action_just_pressed("reload"):
		if weapon_manager:
			weapon_manager.start_reload()

func _on_health_changed(current: float, max_h: float) -> void:
	player_health_changed.emit(current, max_h)

func _on_ammo_changed(mag: int, reserve: int) -> void:
	player_ammo_changed.emit(mag, reserve)

func _on_died(_killer_team: int) -> void:
	is_active = false
	player_died.emit()
