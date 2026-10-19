class_name ThirdPersonController
extends CharacterBody3D
## Third-person player controller for Yangon Life.
##
## Controls WASD movement, sprinting tied to NeedsManager stamina, jumping,
## camera rotation via mouse capture, interaction triggering, and save/load persistence.

const MOVE_SPEED: float = 5.0
const SPRINT_SPEED: float = 8.0
const JUMP_VELOCITY: float = 4.5
const MOUSE_SENSITIVITY: float = 0.003
const PITCH_MIN: float = deg_to_rad(-80.0)
const PITCH_MAX: float = deg_to_rad(60.0)

@export var move_speed: float = MOVE_SPEED
@export var sprint_speed: float = SPRINT_SPEED
@export var jump_velocity: float = JUMP_VELOCITY
@export var mouse_sensitivity: float = MOUSE_SENSITIVITY

@onready var camera_yaw: Node3D = $CameraYaw
@onready var spring_arm: SpringArm3D = $CameraYaw/SpringArm3D
@onready var camera: Camera3D = $CameraYaw/SpringArm3D/Camera3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("player")

	var gm: Node = get_node_or_null("/root/GameManager")
	if gm:
		if gm.has_signal("game_paused"):
			gm.connect("game_paused", _on_game_paused)
		if gm.has_signal("game_resumed"):
			gm.connect("game_resumed", _on_game_resumed)

func _unhandled_input(event: InputEvent) -> void:
	# Pause handling: call GameManager.toggle_pause()
	if event.is_action_pressed("pause"):
		var gm: Node = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("toggle_pause"):
			gm.call("toggle_pause")
		return

	if _is_paused():
		return

	# Mouse capture on click
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Camera rotation: mouse motion rotates player Y axis (yaw) and spring arm X axis (pitch)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		rotate_y(-motion.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-motion.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, PITCH_MIN, PITCH_MAX)

	# Interaction: call InteractionManager.trigger_interaction()
	if event.is_action_pressed("interact"):
		var im: Node = get_node_or_null("/root/InteractionManager")
		if im and im.has_method("trigger_interaction"):
			im.call("trigger_interaction")

func _physics_process(delta: float) -> void:
	if _is_paused():
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	# Determine sprint speed (allowed only if NeedsManager.can_sprint())
	var can_sprint: bool = false
	var nm: Node = get_node_or_null("/root/NeedsManager")
	if nm and nm.has_method("can_sprint"):
		can_sprint = nm.call("can_sprint")
	var is_sprinting: bool = Input.is_action_pressed("sprint") and can_sprint
	var current_speed: float = sprint_speed if is_sprinting else move_speed

	# Movement: WASD vector relative to player facing direction
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)

	move_and_slide()

func _is_paused() -> bool:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and "is_paused" in gm:
		return bool(gm.get("is_paused"))
	return get_tree().paused

func _on_game_paused() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_game_resumed() -> void:
	pass

## Returns player transform data for persistent save files
func get_save_data() -> Dictionary:
	var pos: Vector3 = global_position if is_inside_tree() else position
	return {
		"position": [pos.x, pos.y, pos.z],
		"rotation_y": rotation.y
	}

## Restores player transform data from persistent save files
func load_save_data(data: Dictionary) -> void:
	if data.has("position"):
		var pos_arr: Variant = data["position"]
		if pos_arr is Array and pos_arr.size() >= 3:
			var target_pos := Vector3(float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))
			if is_inside_tree():
				global_position = target_pos
			else:
				position = target_pos
	if data.has("rotation_y"):
		rotation.y = float(data["rotation_y"])
