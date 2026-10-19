class_name TrafficCar
extends CharacterBody3D
## Automated road traffic vehicle following street waypoints or lanes for Yangon Life.
##
## Represents city buses (YBS), taxis, and sedans.
## Follows waypoint paths, uses front RayCast3D to brake for obstacles (pedestrians/vehicles),
## and responds to road traction conditions under rain or monsoon weather.

@export var travel_speed: float = 8.0 # m/s
@export var waypoints: Array[Vector3] = []
@export var car_type: String = "ybs_bus" # "ybs_bus", "taxi", "sedan"

var current_waypoint_index: int = 0
var current_speed: float = 0.0
var is_braking: bool = false
var tire_traction: float = 1.0

var obstacle_ray: RayCast3D = null

func _ready() -> void:
	add_to_group("traffic_cars")
	
	# Layer 3 = Vehicles (4), Mask = 1 | 2 | 3 (World | Characters | Vehicles = 7)
	collision_layer = 4
	collision_mask = 7

	# Find or configure forward obstacle raycast
	obstacle_ray = get_node_or_null("ObstacleRay") as RayCast3D
	if obstacle_ray == null:
		obstacle_ray = RayCast3D.new()
		obstacle_ray.name = "ObstacleRay"
		obstacle_ray.target_position = Vector3(0.0, 0.0, -6.0)
		obstacle_ray.collision_mask = 7
		obstacle_ray.enabled = true
		add_child(obstacle_ray)
	else:
		obstacle_ray.target_position = Vector3(0.0, 0.0, -6.0)
		obstacle_ray.collision_mask = 7
		obstacle_ray.enabled = true

	# Listen to weather controller if available in tree
	_connect_to_weather()

func _physics_process(delta: float) -> void:
	advance_traffic(delta)

## Advances vehicle along road waypoints and applies collision avoidance
func advance_traffic(delta: float) -> void:
	var obstacle_ahead: bool = false
	if obstacle_ray != null and obstacle_ray.is_colliding():
		var col: Object = obstacle_ray.get_collider()
		if col != self:
			obstacle_ahead = true

	# Braking vs Acceleration
	var target_speed: float = 0.0
	if obstacle_ahead:
		is_braking = true
		target_speed = 0.0
	else:
		is_braking = false
		target_speed = travel_speed * tire_traction

	var accel: float = 16.0 if is_braking else (6.0 * tire_traction)
	current_speed = move_toward(current_speed, target_speed, accel * delta)

	# Follow waypoints if assigned
	if waypoints.is_empty():
		var forward_dir: Vector3 = -transform.basis.z.normalized()
		velocity.x = forward_dir.x * current_speed
		velocity.z = forward_dir.z * current_speed
		if not is_on_floor():
			velocity.y -= 9.8 * delta
		else:
			velocity.y = 0.0
		move_and_slide()
		return

	var target_pt: Vector3 = waypoints[current_waypoint_index]
	var diff: Vector3 = target_pt - global_position
	diff.y = 0.0
	var dist: float = diff.length()

	# Reached waypoint -> advance to next
	if dist < 2.5:
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()
		target_pt = waypoints[current_waypoint_index]
		diff = target_pt - global_position
		diff.y = 0.0
		dist = diff.length()

	# Rotate toward next waypoint
	if dist > 0.1:
		var move_dir: Vector3 = diff.normalized()
		var target_yaw: float = atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, minf(4.0 * delta * tire_traction, 1.0))

	var forward: Vector3 = -transform.basis.z.normalized()
	velocity.x = forward.x * current_speed
	velocity.z = forward.z * current_speed
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	move_and_slide()

## Assigns a new array of waypoint coordinates for the car to follow
func set_waypoints(points: Array[Vector3]) -> void:
	waypoints = points
	current_waypoint_index = 0

## Adjusts tire traction (e.g. wet or flooded roads during rain/monsoon)
func set_tire_traction(traction: float) -> void:
	tire_traction = clampf(traction, 0.2, 1.0)

func _connect_to_weather() -> void:
	var weather_nodes: Array[Node] = get_tree().get_nodes_in_group("weather_controller")
	if not weather_nodes.is_empty():
		var wc: Node = weather_nodes[0]
		if wc.has_signal("weather_changed"):
			wc.weather_changed.connect(_on_weather_changed)
		if wc.has_method("get_vehicle_traction"):
			set_tire_traction(float(wc.call("get_vehicle_traction")))

func _on_weather_changed(_weather_type: int) -> void:
	var weather_nodes: Array[Node] = get_tree().get_nodes_in_group("weather_controller")
	if not weather_nodes.is_empty():
		var wc: Node = weather_nodes[0]
		if wc.has_method("get_vehicle_traction"):
			set_tire_traction(float(wc.call("get_vehicle_traction")))
