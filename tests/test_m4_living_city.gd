extends SceneTree
## Automated Headless Test Suite for Milestone M4:
## Living City NPCs, Road Traffic & Weather Dynamics

var tests_passed: int = 0
var tests_failed: int = 0

const NPCPedestrianScript = preload("res://scripts/npcs/npc_pedestrian.gd")
const TrafficCarScript = preload("res://scripts/vehicles/traffic_car.gd")
const WeatherControllerScript = preload("res://scripts/simulation/weather_controller.gd")
const TimeManagerScript = preload("res://scripts/simulation/time_manager.gd")
const NeedsManagerScript = preload("res://scripts/simulation/needs_manager.gd")
const InteractionManagerScript = preload("res://scripts/interaction/interaction_manager.gd")

var _tm: Node
var _nm: Node
var _im: Node

func _init() -> void:
	process_frame.connect(_run_all_tests, CONNECT_ONE_SHOT)

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		print("  [PASS] %s" % test_name)
		tests_passed += 1
	else:
		printerr("  [FAIL] %s" % test_name)
		tests_failed += 1

func _setup_autoloads() -> void:
	if not root.has_node("TimeManager"):
		_tm = TimeManagerScript.new()
		_tm.name = "TimeManager"
		root.add_child(_tm)
	else:
		_tm = root.get_node("TimeManager")

	if not root.has_node("NeedsManager"):
		_nm = NeedsManagerScript.new()
		_nm.name = "NeedsManager"
		root.add_child(_nm)
	else:
		_nm = root.get_node("NeedsManager")

	if not root.has_node("InteractionManager"):
		_im = InteractionManagerScript.new()
		_im.name = "InteractionManager"
		root.add_child(_im)
	else:
		_im = root.get_node("InteractionManager")

func _run_all_tests() -> void:
	print("==================================================")
	print("  M4 LIVING CITY, TRAFFIC & WEATHER DYNAMICS TESTS")
	print("==================================================")

	_setup_autoloads()

	_test_npc_pedestrian_script()
	_test_npc_pedestrian_scene()
	_test_traffic_car_script()
	_test_traffic_car_scene()
	_test_weather_controller_script()
	_test_weather_environment_scene()

	print("\n--------------------------------------------------")
	print("M4 TEST RESULTS: %d PASSED, %d FAILED" % [tests_passed, tests_failed])
	print("--------------------------------------------------")

	if tests_failed == 0:
		print(">> ALL M4 SYSTEMS VERIFIED WITH 0 ERRORS! <<\n")
		quit(0)
	else:
		printerr(">> M4 TESTS ENCOUNTERED FAILURES! <<\n")
		quit(1)

func _test_npc_pedestrian_script() -> void:
	print("\n[Suite 1: NPCPedestrian Logic & Distance LOD]")
	var npc := NPCPedestrianScript.new()
	root.add_child(npc)
	npc.global_position = Vector3(0, 0, 0)

	_assert(npc.npc_name == "U Kyaw", "Default NPC name is U Kyaw")
	_assert(npc.archetype == "office_worker", "Default archetype is office_worker")
	_assert(is_equal_approx(npc.walk_speed, 2.0), "Default walk speed is 2.0 m/s")

	# Test Burmese/English contextual dialogue for each archetype
	npc.archetype = "monk"
	var monk_talk: String = npc.talk_to_player()
	_assert(monk_talk.contains("Mingalarba") and (monk_talk.contains("peace") or monk_talk.contains("မင်္ဂလာပါ")), "Monk greeting contains peaceful Burmese blessing")

	npc.archetype = "office_worker"
	var office_talk: String = npc.talk_to_player()
	_assert(office_talk.contains("Sule") or office_talk.contains("office"), "Office worker greeting references Sule / office shift")

	npc.archetype = "student"
	var student_talk: String = npc.talk_to_player()
	_assert(student_talk.contains("University") or student_talk.contains("exams"), "Student greeting references university / exams")

	npc.archetype = "street_vendor"
	var vendor_talk: String = npc.talk_to_player()
	_assert(vendor_talk.contains("Mohinga") or vendor_talk.contains("noodles"), "Vendor greeting offers Mohinga / street food")

	npc.archetype = "shopper"
	var shopper_talk: String = npc.talk_to_player()
	_assert(shopper_talk.contains("Market") or shopper_talk.contains("Bogyoke"), "Shopper greeting references Bogyoke Market / shopping")

	_assert(npc.is_interacting == true, "talk_to_player sets is_interacting to true")

	# Test Destination Setting
	npc.set_target_destination(Vector3(10, 0, 15))
	_assert(npc.has_destination == true, "set_target_destination enables has_destination flag")
	_assert(npc.target_destination == Vector3(10, 0, 15), "target_destination matches assigned vector")

	# Test Three-Tier LOD Switching
	# Full LOD (< 25m)
	npc.update_lod(Vector3(10, 0, 0)) # distance = 10m
	_assert(npc.current_lod == NPCPedestrianScript.LOD_FULL, "Distance < 25m sets LOD_FULL (0)")
	_assert(npc.visible == true, "LOD_FULL has visible = true")
	_assert(npc.collision_layer == 2, "LOD_FULL has collision_layer = 2 (Characters)")

	# Simplified LOD (25m - 60m)
	npc.update_lod(Vector3(40, 0, 0)) # distance = 40m
	_assert(npc.current_lod == NPCPedestrianScript.LOD_SIMPLIFIED, "Distance 25m-60m sets LOD_SIMPLIFIED (1)")
	_assert(npc.visible == true, "LOD_SIMPLIFIED has visible = true")
	_assert(npc.collision_layer == 0, "LOD_SIMPLIFIED disables collision (layer = 0)")

	# Offscreen LOD (> 60m)
	npc.update_lod(Vector3(100, 0, 0)) # distance = 100m
	_assert(npc.current_lod == NPCPedestrianScript.LOD_OFFSCREEN, "Distance > 60m sets LOD_OFFSCREEN (2)")
	_assert(npc.visible == false, "LOD_OFFSCREEN hides mesh (visible = false)")
	_assert(npc.collision_layer == 0, "LOD_OFFSCREEN disables collision (layer = 0)")

	# Test Schedule Evaluation
	npc.schedule_stops = [Vector3(0, 0, 0), Vector3(20, 0, 10), Vector3(40, 0, 20)]
	npc.evaluate_schedule(0) # 00:00 -> index 0
	_assert(npc.current_stop_index == 0, "Schedule at 00:00 selects stop 0")
	_assert(npc.target_destination == Vector3(0, 0, 0), "Target destination updated to stop 0")

	npc.evaluate_schedule(8) # 08:00 -> index 1
	_assert(npc.current_stop_index == 1, "Schedule at 08:00 selects stop 1")
	_assert(npc.target_destination == Vector3(20, 0, 10), "Target destination updated to stop 1")

	npc.evaluate_schedule(17) # 17:00 -> index 2
	_assert(npc.current_stop_index == 2, "Schedule at 17:00 selects stop 2")
	_assert(npc.target_destination == Vector3(40, 0, 20), "Target destination updated to stop 2")

	npc.queue_free()

func _test_npc_pedestrian_scene() -> void:
	print("\n[Suite 2: NPCPedestrian Scene Composition]")
	var scene: PackedScene = load("res://scenes/npcs/npc_pedestrian.tscn")
	_assert(scene != null, "scenes/npcs/npc_pedestrian.tscn loaded successfully")
	var inst := scene.instantiate() as NPCPedestrian
	root.add_child(inst)
	_assert(inst != null, "Scene instantiated as NPCPedestrian CharacterBody3D")

	_assert(inst.collision_layer == 2, "Pedestrian root collision_layer = 2 (Characters)")

	var col: CollisionShape3D = inst.get_node_or_null("CollisionShape3D")
	_assert(col != null and col.shape is CapsuleShape3D, "CollisionShape3D has CapsuleShape3D")
	var cap := col.shape as CapsuleShape3D
	_assert(is_equal_approx(cap.radius, 0.35) and is_equal_approx(cap.height, 1.8), "CapsuleShape3D dimensions are radius=0.35, height=1.8")

	var mesh_inst: MeshInstance3D = inst.get_node_or_null("MeshInstance3D")
	_assert(mesh_inst != null and mesh_inst.mesh is CapsuleMesh, "Visual mesh is CapsuleMesh")

	var talk_area: Area3D = inst.get_node_or_null("TalkArea")
	_assert(talk_area != null, "Pedestrian has TalkArea Area3D")
	_assert(talk_area.collision_layer == 8, "TalkArea collision_layer = 8 (Layer 4 Interactables)")

	var zone: Node = inst.get_node_or_null("TalkArea/InteractableZone")
	_assert(zone != null, "TalkArea has child InteractableZone")
	_assert(zone.get("prompt_text") == "Talk to Pedestrian", "InteractableZone prompt is 'Talk to Pedestrian'")

	inst.queue_free()

func _test_traffic_car_script() -> void:
	print("\n[Suite 3: TrafficCar Logic & Road Navigation]")
	var car := TrafficCarScript.new()
	root.add_child(car)

	_assert(is_equal_approx(car.travel_speed, 8.0), "Default travel speed is 8.0 m/s")
	_assert(car.car_type == "ybs_bus", "Default car_type is 'ybs_bus'")
	_assert(car.collision_layer == 4, "Car collision_layer = 4 (Layer 3 Vehicles)")
	_assert(car.collision_mask == 7, "Car collision_mask = 7 (World|Characters|Vehicles)")

	# Waypoint Assignment
	var pts: Array[Vector3] = [Vector3(0, 0, 0), Vector3(0, 0, 30), Vector3(20, 0, 30)]
	car.set_waypoints(pts)
	_assert(car.waypoints.size() == 3, "set_waypoints populated 3 road points")
	_assert(car.current_waypoint_index == 0, "current_waypoint_index initialized to 0")

	# Road Traction
	car.set_tire_traction(0.7)
	_assert(is_equal_approx(car.tire_traction, 0.7), "set_tire_traction correctly updates traction")

	# Advance Traffic Step
	car.global_position = Vector3(0, 0, 0)
	car.advance_traffic(0.1)
	_assert(car.current_speed > 0.0, "Car accelerates toward travel speed when road is clear")

	car.queue_free()

func _test_traffic_car_scene() -> void:
	print("\n[Suite 4: TrafficCar Scene Composition & Livery]")
	var scene: PackedScene = load("res://scenes/vehicles/traffic_car.tscn")
	_assert(scene != null, "scenes/vehicles/traffic_car.tscn loaded successfully")
	var car := scene.instantiate() as TrafficCar
	root.add_child(car)
	_assert(car != null, "Scene instantiated as TrafficCar CharacterBody3D")

	_assert(car.collision_layer == 4, "TrafficCar collision_layer = 4 (Layer 3 Vehicles)")
	_assert(car.collision_mask == 7, "TrafficCar collision_mask = 7 (World|Characters|Vehicles)")

	var col: CollisionShape3D = car.get_node_or_null("CollisionShape3D")
	_assert(col != null and col.shape is BoxShape3D, "CollisionShape3D has BoxShape3D")
	var box := col.shape as BoxShape3D
	_assert(is_equal_approx(box.size.x, 2.2) and is_equal_approx(box.size.y, 2.5) and is_equal_approx(box.size.z, 7.0), "Bus BoxShape3D dimensions are (2.2, 2.5, 7.0)")

	var mesh_inst: MeshInstance3D = car.get_node_or_null("MeshInstance3D")
	_assert(mesh_inst != null and mesh_inst.mesh is BoxMesh, "Car has BoxMesh visual body")
	var stripe: MeshInstance3D = car.get_node_or_null("MeshInstance3D/StripeYellow")
	_assert(stripe != null, "Car includes YBS yellow trim stripe livery")

	var ray: RayCast3D = car.get_node_or_null("ObstacleRay")
	_assert(ray != null, "Car has forward ObstacleRay RayCast3D")
	_assert(is_equal_approx(ray.target_position.z, -6.0), "ObstacleRay target_position extends 6.0m forward (z = -6.0)")

	car.queue_free()

func _test_weather_controller_script() -> void:
	print("\n[Suite 5: WeatherController Day/Night & Simulation Effects]")
	var wc := WeatherControllerScript.new()
	root.add_child(wc)

	_assert(WeatherControllerScript.CLEAR == 0, "CLEAR constant is 0")
	_assert(WeatherControllerScript.CLOUDY == 1, "CLOUDY constant is 1")
	_assert(WeatherControllerScript.RAIN == 2, "RAIN constant is 2")
	_assert(WeatherControllerScript.MONSOON == 3, "MONSOON constant is 3")

	# Test Celestial Sun Movement
	wc.update_sun(6, 0) # Sunrise
	_assert(is_equal_approx(wc.get_sun_angle(), 0.0), "06:00 sunrise sun angle is 0.0°")
	_assert(is_equal_approx(wc.get_sun_energy(), 0.4), "06:00 dawn sun energy is 0.4")

	wc.update_sun(12, 0) # Noon
	_assert(is_equal_approx(wc.get_sun_angle(), 90.0), "12:00 noon sun angle is 90.0°")
	_assert(is_equal_approx(wc.get_sun_energy(), 1.2), "12:00 noon sun energy is 1.2")

	wc.update_sun(18, 0) # Sunset
	_assert(is_equal_approx(wc.get_sun_angle(), 180.0), "18:00 sunset sun angle is 180.0°")
	_assert(is_equal_approx(wc.get_sun_energy(), 0.4), "18:00 dusk sun energy is 0.4")

	wc.update_sun(0, 0) # Midnight
	_assert(is_equal_approx(wc.get_sun_angle(), 270.0), "00:00 midnight sun angle is 270.0°")
	_assert(is_equal_approx(wc.get_sun_energy(), 0.05), "00:00 night moonlight energy is 0.05")

	# Test Weather Types and System Dynamics
	wc.set_weather(WeatherControllerScript.CLEAR)
	_assert(wc.get_weather() == WeatherControllerScript.CLEAR, "Weather set to CLEAR")
	_assert(wc.get_weather_name() == "Clear", "Weather name is 'Clear'")
	_assert(is_equal_approx(wc.get_vehicle_traction(), 1.0), "Clear weather provides 1.0 road traction")
	_assert(is_equal_approx(_nm.stress_growth, 1.5), "Clear weather maintains normal player stress growth (1.5)")

	wc.set_weather(WeatherControllerScript.RAIN)
	_assert(wc.get_weather() == WeatherControllerScript.RAIN, "Weather set to RAIN")
	_assert(wc.get_weather_name() == "Rain", "Weather name is 'Rain'")
	_assert(wc.get_vehicle_traction() < 1.0, "Rain reduces vehicle tire traction (< 1.0)")
	_assert(_nm.stress_growth > 1.5, "Rain slightly increases player stress growth (> 1.5)")

	wc.set_weather(WeatherControllerScript.MONSOON)
	_assert(wc.get_weather() == WeatherControllerScript.MONSOON, "Weather set to MONSOON")
	_assert(wc.get_weather_name() == "Monsoon", "Weather name is 'Monsoon'")
	_assert(wc.get_vehicle_traction() <= 0.55, "Monsoon sharply reduces vehicle traction (<= 0.55)")
	_assert(_nm.stress_growth >= 2.5, "Monsoon raises player stress growth significantly (>= 2.5)")

	# Reset weather and cleanup
	wc.set_weather(WeatherControllerScript.CLEAR)
	wc.queue_free()

func _test_weather_environment_scene() -> void:
	print("\n[Suite 6: WeatherEnvironment Scene Integration]")
	var scene: PackedScene = load("res://scenes/world/weather_environment.tscn")
	_assert(scene != null, "scenes/world/weather_environment.tscn loaded successfully")
	var env := scene.instantiate() as Node3D
	root.add_child(env)
	_assert(env != null, "WeatherEnvironment instantiated as Node3D")

	var sun: DirectionalLight3D = env.get_node_or_null("SunLight")
	_assert(sun != null, "WeatherEnvironment has SunLight DirectionalLight3D")
	_assert(sun.shadow_enabled == true, "SunLight shadows are enabled")

	var rain: CPUParticles3D = env.get_node_or_null("RainParticles")
	_assert(rain != null, "WeatherEnvironment has RainParticles CPUParticles3D")
	_assert(rain.amount >= 300, "RainParticles amount >= 300")
	_assert(rain.emission_shape == CPUParticles3D.EMISSION_SHAPE_BOX, "RainParticles emission_shape is Box")

	var wc := env as WeatherController
	_assert(wc != null, "WeatherEnvironment script is WeatherController")

	# Test particle toggling with weather states
	wc.set_weather(WeatherControllerScript.CLEAR)
	_assert(rain.emitting == false, "RainParticles emitting is false in CLEAR weather")

	wc.set_weather(WeatherControllerScript.RAIN)
	_assert(rain.emitting == true, "RainParticles emitting is true in RAIN weather")
	_assert(rain.amount == 300, "RainParticles amount is 300 in standard rain")

	wc.set_weather(WeatherControllerScript.MONSOON)
	_assert(rain.emitting == true, "RainParticles emitting is true in MONSOON weather")
	_assert(rain.amount >= 600, "RainParticles amount is elevated to >= 600 in monsoon storm")

	wc.set_weather(WeatherControllerScript.CLEAR)
	_assert(rain.emitting == false, "RainParticles stopped emitting after returning to CLEAR")

	env.queue_free()
