class_name VehicleController
extends CharacterBody3D
## Reusable vehicle physics controller for Yangon Life.
##
## Supports motorized vehicles (taxis, cars) and manual vehicles (bicycles).
## Handles player embarking/disembarking, fuel consumption, taxi fare metering,
## third-person chase camera, and persistent state serialization.

signal driver_entered(driver: Node3D)
signal driver_exited
signal fuel_changed(current: float, max_capacity: float)
signal fare_updated(fare: int, distance: float)

@export var vehicle_name: String = "Yellow-Top Taxi"
@export var max_speed: float = 16.0 # m/s (~58 km/h)
@export var acceleration: float = 8.0 # m/s^2
@export var braking: float = 14.0 # m/s^2
@export var reverse_speed: float = 6.0 # m/s
@export var steering_speed: float = 2.2 # rad/s
@export var max_steering_angle: float = 0.55 # radians (~32 degrees)
@export var fuel_capacity: float = 50.0 # liters
@export var fuel_consumption_rate: float = 0.05 # liters/sec at full throttle
@export var is_motorized: bool = true

var current_speed: float = 0.0
var current_steering: float = 0.0
var current_fuel: float = 50.0
var is_driven: bool = false
var driver_node: Node3D = null
var taxi_meter_active: bool = false
var trip_distance: float = 0.0
var trip_fare: int = 0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

var _door_player_near: Node3D = null
var _wheel_fl: Node3D = null
var _wheel_fr: Node3D = null
var _wheel_rl: Node3D = null
var _wheel_rr: Node3D = null
var _wheel_f: Node3D = null
var _wheel_r: Node3D = null

func _init() -> void:
	collision_layer = 4 # Layer 3 (Vehicles)
	collision_mask = 5 # Layer 1 World (1) | Layer 3 Vehicles (4)

func _ready() -> void:
	add_to_group("vehicles")
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(3, true)

	if not is_motorized:
		fuel_capacity = 0.0
		current_fuel = 0.0
	else:
		current_fuel = minf(current_fuel, fuel_capacity)

	_cache_wheel_nodes()
	_setup_door_area()

func _cache_wheel_nodes() -> void:
	_wheel_fl = get_node_or_null("Wheel_FL")
	_wheel_fr = get_node_or_null("Wheel_FR")
	_wheel_rl = get_node_or_null("Wheel_RL")
	_wheel_rr = get_node_or_null("Wheel_RR")
	_wheel_f = get_node_or_null("Wheel_F")
	_wheel_r = get_node_or_null("Wheel_R")

func _setup_door_area() -> void:
	var door: Area3D = get_node_or_null("DoorArea")
	if door:
		# Layer 4 = Interactables (bitmask 8), Mask = Layer 2 Characters (bitmask 2)
		door.set_collision_layer_value(4, true)
		door.set_collision_mask_value(2, true)
		door.monitoring = true
		if not door.body_entered.is_connected(_on_door_body_entered):
			door.body_entered.connect(_on_door_body_entered)
		if not door.body_exited.is_connected(_on_door_body_exited):
			door.body_exited.connect(_on_door_body_exited)

func _on_door_body_entered(body: Node3D) -> void:
	if _is_player_node(body):
		_door_player_near = body
		var im: Node = get_node_or_null("/root/InteractionManager")
		if im and im.has_method("register_interactable"):
			var door: Area3D = get_node_or_null("DoorArea")
			if door:
				im.call("register_interactable", door, "Drive " + vehicle_name)

func _on_door_body_exited(body: Node3D) -> void:
	if _door_player_near == body:
		_door_player_near = null
		var im: Node = get_node_or_null("/root/InteractionManager")
		if im and im.has_method("unregister_interactable"):
			var door: Area3D = get_node_or_null("DoorArea")
			if door:
				im.call("unregister_interactable", door)

func _is_player_node(node: Node) -> bool:
	if node == null:
		return false
	if node.is_in_group("player"):
		return true
	if node.name == "Player" or node.name.begins_with("Player"):
		return true
	return false

## Called when interaction trigger occurs on this vehicle or its DoorArea
func interact() -> void:
	if not is_driven:
		var target_driver: Node3D = _door_player_near
		if target_driver == null:
			target_driver = _get_scene_player()
		if target_driver != null:
			enter_vehicle(target_driver)

func _unhandled_input(event: InputEvent) -> void:
	# Enter vehicle when standing outside near the door
	if not is_driven and _door_player_near != null:
		if event.is_action_pressed("enter_vehicle"):
			enter_vehicle(_door_player_near)
			return

	if not is_driven:
		return

	# Exit vehicle on enter_vehicle key press (default 'F')
	if event.is_action_pressed("enter_vehicle"):
		exit_vehicle()
		return

	# Third-person chase camera rotation via mouse motion
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		var cam_mount: Node3D = get_node_or_null("CameraMount")
		var spring_arm: SpringArm3D = get_node_or_null("CameraMount/SpringArm3D")
		if cam_mount:
			cam_mount.rotate_y(-motion.relative.x * 0.003)
		if spring_arm:
			spring_arm.rotate_x(-motion.relative.y * 0.003)
			spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-60.0), deg_to_rad(45.0))

func _physics_process(delta: float) -> void:
	# Gravity simulation
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if not is_driven:
		# Natural deceleration if no driver
		if abs(current_speed) > 0.01:
			current_speed = move_toward(current_speed, 0.0, braking * delta)
			var fwd: Vector3 = -global_transform.basis.z
			velocity.x = fwd.x * current_speed
			velocity.z = fwd.z * current_speed
		else:
			current_speed = 0.0
			velocity.x = 0.0
			velocity.z = 0.0
		move_and_slide()
		return

	# Handle controls when driven
	_process_driving(delta)
	move_and_slide()

	# Update driver position to follow vehicle
	if driver_node and is_instance_valid(driver_node):
		driver_node.global_position = global_position

func _process_driving(delta: float) -> void:
	var throttle: float = 0.0
	if Input.is_action_pressed("move_forward"):
		throttle += 1.0
	if Input.is_action_pressed("move_backward"):
		throttle -= 1.0

	var steer_input: float = 0.0
	if Input.is_action_pressed("move_left"):
		steer_input += 1.0
	if Input.is_action_pressed("move_right"):
		steer_input -= 1.0

	var handbrake: bool = Input.is_action_pressed("jump")

	# Fuel check for motorized vehicles
	var out_of_fuel: bool = is_motorized and current_fuel <= 0.0
	if out_of_fuel:
		throttle = 0.0

	# Fuel consumption during throttle
	if is_motorized and not out_of_fuel and abs(throttle) > 0.0:
		var fuel_spent: float = fuel_consumption_rate * delta
		current_fuel = maxf(0.0, current_fuel - fuel_spent)
		fuel_changed.emit(current_fuel, fuel_capacity)

	# Speed acceleration & braking
	if handbrake:
		current_speed = move_toward(current_speed, 0.0, braking * 2.0 * delta)
	elif throttle > 0.0:
		if current_speed < 0.0:
			current_speed = move_toward(current_speed, 0.0, braking * delta)
		else:
			current_speed = move_toward(current_speed, max_speed, acceleration * delta)
	elif throttle < 0.0:
		if current_speed > 0.0:
			current_speed = move_toward(current_speed, 0.0, braking * delta)
		else:
			current_speed = move_toward(current_speed, -reverse_speed, acceleration * delta)
	else:
		current_speed = move_toward(current_speed, 0.0, (braking * 0.35) * delta)

	# Steering interpolation
	var target_steering: float = steer_input * max_steering_angle
	current_steering = move_toward(current_steering, target_steering, steering_speed * delta)

	# Yaw rotation based on movement speed and steering
	if abs(current_speed) > 0.1:
		var turn_factor: float = (current_speed / max_speed) * 2.4
		rotate_y(current_steering * turn_factor * delta)

	# Vehicle forward velocity
	var forward_dir: Vector3 = -global_transform.basis.z
	velocity.x = forward_dir.x * current_speed
	velocity.z = forward_dir.z * current_speed

	# Update visual wheel mesh rotations
	_animate_wheels(delta)

	# Camera auto-centering when moving forward
	var cam_mount: Node3D = get_node_or_null("CameraMount")
	if cam_mount and abs(current_speed) > 1.0:
		cam_mount.rotation.y = lerp_angle(cam_mount.rotation.y, 0.0, 2.5 * delta)

	# Taxi meter tracking
	if taxi_meter_active:
		var frame_dist: float = abs(current_speed) * delta
		trip_distance += frame_dist
		trip_fare = 1500 + int(trip_distance * 1.2)
		fare_updated.emit(trip_fare, trip_distance)

func _animate_wheels(delta: float) -> void:
	var roll_angle: float = (-current_speed * delta) / 0.35

	if _wheel_fl:
		_wheel_fl.rotate_x(roll_angle)
	if _wheel_fr:
		_wheel_fr.rotate_x(roll_angle)
	if _wheel_rl:
		_wheel_rl.rotate_x(roll_angle)
	if _wheel_rr:
		_wheel_rr.rotate_x(roll_angle)
	if _wheel_f:
		_wheel_f.rotate_x(roll_angle)
	if _wheel_r:
		_wheel_r.rotate_x(roll_angle)

## Embarks driver into vehicle, transferring camera and inputs
func enter_vehicle(driver: Node3D) -> bool:
	if is_driven or driver == null:
		return false

	is_driven = true
	driver_node = driver

	# Unregister interactable prompt if open
	if is_inside_tree():
		var im: Node = get_node_or_null("/root/InteractionManager")
		if im and im.has_method("clear_interactable"):
			im.call("clear_interactable")

	# Deactivate driver character body and hide
	driver.visible = false
	if "process_mode" in driver:
		driver.process_mode = Node.PROCESS_MODE_DISABLED

	# Deactivate player camera, activate vehicle camera
	var driver_cam: Camera3D = driver.get_node_or_null("CameraYaw/SpringArm3D/Camera3D") as Camera3D
	if driver_cam:
		driver_cam.current = false

	var veh_cam: Camera3D = get_node_or_null("CameraMount/SpringArm3D/Camera3D") as Camera3D
	if veh_cam:
		veh_cam.current = true

	driver_entered.emit(driver)
	return true

## Disembarks driver at ExitPoint, restoring driver camera and controls
func exit_vehicle() -> void:
	if not is_driven or driver_node == null:
		return

	var exit_pos: Vector3 = Vector3(-1.5, 0.0, 0.0)
	var exit_marker: Node3D = get_node_or_null("ExitPoint")
	if is_inside_tree():
		if exit_marker:
			exit_pos = exit_marker.global_position
		else:
			exit_pos = global_position + (-global_transform.basis.x * 1.5)
		driver_node.global_position = exit_pos
	else:
		if exit_marker:
			exit_pos = exit_marker.position
		else:
			exit_pos = position + (-transform.basis.x * 1.5)
		driver_node.position = exit_pos

	driver_node.visible = true
	if "process_mode" in driver_node:
		driver_node.process_mode = Node.PROCESS_MODE_ALWAYS

	# Switch camera back to player
	var veh_cam: Camera3D = get_node_or_null("CameraMount/SpringArm3D/Camera3D") as Camera3D
	if veh_cam:
		veh_cam.current = false

	var driver_cam: Camera3D = driver_node.get_node_or_null("CameraYaw/SpringArm3D/Camera3D") as Camera3D
	if driver_cam:
		driver_cam.current = true

	driver_node = null
	is_driven = false
	current_speed = 0.0
	current_steering = 0.0

	driver_exited.emit()

## Refuels vehicle up to fuel_capacity; returns actual amount added in liters
func refuel(amount: float) -> float:
	if not is_motorized or fuel_capacity <= 0.0 or amount <= 0.0:
		return 0.0

	var space: float = fuel_capacity - current_fuel
	var actual_added: float = clampf(amount, 0.0, space)
	current_fuel += actual_added
	fuel_changed.emit(current_fuel, fuel_capacity)
	return actual_added

## Activates taxi meter for fare calculation
func start_taxi_meter() -> void:
	taxi_meter_active = true
	trip_distance = 0.0
	trip_fare = 1500
	fare_updated.emit(trip_fare, trip_distance)

## Stops taxi meter and returns total collected fare (Base 1,500 MMK + 1.2 MMK/meter)
func stop_taxi_meter() -> int:
	taxi_meter_active = false
	var final_fare: int = trip_fare
	fare_updated.emit(final_fare, trip_distance)
	return final_fare

func _get_scene_player() -> Node3D:
	var player_nodes := get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0 and player_nodes[0] is Node3D:
		return player_nodes[0] as Node3D
	return null

## Exports persistent vehicle state for save files
func get_save_data() -> Dictionary:
	var pos: Vector3 = global_position if is_inside_tree() else position
	return {
		"vehicle_name": vehicle_name,
		"position": [pos.x, pos.y, pos.z],
		"rotation_y": rotation.y,
		"current_fuel": current_fuel,
		"is_driven": is_driven,
		"taxi_meter_active": taxi_meter_active,
		"trip_distance": trip_distance,
		"trip_fare": trip_fare
	}

## Restores vehicle state from persistent save dictionary
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
	if data.has("current_fuel"):
		current_fuel = float(data["current_fuel"])
		fuel_changed.emit(current_fuel, fuel_capacity)
	if data.has("taxi_meter_active"):
		taxi_meter_active = bool(data["taxi_meter_active"])
	if data.has("trip_distance"):
		trip_distance = float(data["trip_distance"])
	if data.has("trip_fare"):
		trip_fare = int(data["trip_fare"])
