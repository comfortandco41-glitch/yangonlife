class_name WeatherController
extends Node3D
## Celestial day/night cycle and dynamic weather simulation for Yangon Life.
##
## Controls directional sun celestial movement, day/night lighting curves,
## atmospheric rain particle emissions, player stress modifiers, and road traction.

signal weather_changed(weather_type: int)

const CLEAR: int = 0
const CLOUDY: int = 1
const RAIN: int = 2
const MONSOON: int = 3

@export var sun_light_path: NodePath
@export var rain_particles_path: NodePath

var current_weather: int = CLEAR
var current_sun_angle: float = 90.0
var current_sun_energy: float = 1.2
var vehicle_traction: float = 1.0

func _ready() -> void:
	add_to_group("weather_controller")

	# Connect to TimeManager signals
	if has_node("/root/TimeManager"):
		var tm: Node = get_node("/root/TimeManager")
		if tm.has_signal("hour_changed"):
			tm.hour_changed.connect(_on_hour_changed)
		if tm.has_signal("time_tick"):
			tm.time_tick.connect(_on_time_tick)

	# Initialize current weather state and celestial alignment
	set_weather(current_weather)
	_update_sun_from_current_time()

## Sets active weather condition and updates simulation systems
func set_weather(weather_type: int) -> void:
	current_weather = clampi(weather_type, CLEAR, MONSOON)

	# Toggle rain particles
	var rain := _get_rain_particles()
	if rain != null:
		match current_weather:
			CLEAR, CLOUDY:
				rain.emitting = false
			RAIN:
				rain.emitting = true
				rain.amount = 300
			MONSOON:
				rain.emitting = true
				rain.amount = 600

	# Adjust player stress growth in NeedsManager
	if has_node("/root/NeedsManager"):
		var nm: Node = get_node("/root/NeedsManager")
		match current_weather:
			CLEAR:
				nm.set("stress_growth", 1.5)
			CLOUDY:
				nm.set("stress_growth", 1.6)
			RAIN:
				nm.set("stress_growth", 2.1)
			MONSOON:
				nm.set("stress_growth", 2.8)

	# Adjust vehicle road traction
	match current_weather:
		CLEAR:
			vehicle_traction = 1.0
		CLOUDY:
			vehicle_traction = 0.95
		RAIN:
			vehicle_traction = 0.75
		MONSOON:
			vehicle_traction = 0.50

	# Propagate traction to all active traffic vehicles
	if is_inside_tree():
		var traffic_cars: Array[Node] = get_tree().get_nodes_in_group("traffic_cars")
		for car in traffic_cars:
			if car.has_method("set_tire_traction"):
				car.call("set_tire_traction", vehicle_traction)

	_update_sun_from_current_time()
	weather_changed.emit(current_weather)

## Updates sun position and energy given hour and minute
func update_sun(hour: int, minute: int) -> void:
	var time_in_hours: float = float(hour) + float(minute) / 60.0
	
	# Celestial angle: 06:00 = 0° (East), 12:00 = 90° (Noon), 18:00 = 180° (West), 24:00 = 270°
	var angle_deg: float = (time_in_hours - 6.0) * 15.0
	if angle_deg < 0.0:
		angle_deg += 360.0
	current_sun_angle = angle_deg

	# Solar energy curve: 1.2 at noon, 0.4 at dusk/dawn, 0.05 at night
	if time_in_hours >= 6.0 and time_in_hours <= 18.0:
		var progress: float = (time_in_hours - 6.0) / 12.0
		var curve: float = sin(progress * PI)
		current_sun_energy = lerpf(0.4, 1.2, curve)
	elif time_in_hours > 5.0 and time_in_hours < 6.0:
		current_sun_energy = lerpf(0.05, 0.4, time_in_hours - 5.0)
	elif time_in_hours > 18.0 and time_in_hours < 19.0:
		current_sun_energy = lerpf(0.4, 0.05, time_in_hours - 18.0)
	else:
		current_sun_energy = 0.05

	# Weather lighting attenuation
	var weather_attenuation: float = 1.0
	match current_weather:
		CLEAR:
			weather_attenuation = 1.0
		CLOUDY:
			weather_attenuation = 0.7
		RAIN:
			weather_attenuation = 0.5
		MONSOON:
			weather_attenuation = 0.25

	var final_energy: float = current_sun_energy * weather_attenuation

	var sun := _get_sun_light()
	if sun != null:
		sun.rotation_degrees = Vector3(-current_sun_angle, -30.0, 0.0)
		sun.light_energy = final_energy

		# Sky lighting tone
		if time_in_hours >= 6.0 and time_in_hours <= 18.0:
			if current_weather >= RAIN:
				sun.light_color = Color(0.7, 0.75, 0.82, 1.0)
			else:
				sun.light_color = Color(1.0, 0.95, 0.88, 1.0)
		else:
			sun.light_color = Color(0.55, 0.65, 0.85, 1.0)

## Returns current weather enum value
func get_weather() -> int:
	return current_weather

## Returns human-readable weather description
func get_weather_name() -> String:
	match current_weather:
		CLEAR:
			return "Clear"
		CLOUDY:
			return "Cloudy"
		RAIN:
			return "Rain"
		MONSOON:
			return "Monsoon"
		_:
			return "Clear"

## Returns active vehicle traction multiplier
func get_vehicle_traction() -> float:
	return vehicle_traction

## Returns active sun angle in degrees
func get_sun_angle() -> float:
	return current_sun_angle

## Returns active sun energy
func get_sun_energy() -> float:
	return current_sun_energy

func _on_hour_changed(hour: int) -> void:
	var minute: int = 0
	if has_node("/root/TimeManager"):
		minute = int(get_node("/root/TimeManager").get("game_minute"))
	update_sun(hour, minute)

func _on_time_tick(hour: int, minute: int) -> void:
	update_sun(hour, minute)

func _update_sun_from_current_time() -> void:
	var hour: int = 12
	var minute: int = 0
	if has_node("/root/TimeManager"):
		var tm: Node = get_node("/root/TimeManager")
		hour = int(tm.get("game_hour"))
		minute = int(tm.get("game_minute"))
	update_sun(hour, minute)

func _get_sun_light() -> DirectionalLight3D:
	if not sun_light_path.is_empty():
		var node := get_node_or_null(sun_light_path)
		if node is DirectionalLight3D:
			return node as DirectionalLight3D
	return get_node_or_null("SunLight") as DirectionalLight3D

func _get_rain_particles() -> CPUParticles3D:
	if not rain_particles_path.is_empty():
		var node := get_node_or_null(rain_particles_path)
		if node is CPUParticles3D:
			return node as CPUParticles3D
	return get_node_or_null("RainParticles") as CPUParticles3D
