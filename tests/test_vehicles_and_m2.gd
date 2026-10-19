extends SceneTree
## Milestone M2 Automated Verification Test Suite
## Verifies VehicleController, TaxiSedan, DeliveryBicycle, JigsawRouteRunner, and Downtown Yangon expansion.

var tests_passed: int = 0
var tests_failed: int = 0

const VehicleControllerScript = preload("res://scripts/vehicles/vehicle_controller.gd")
const JigsawRouteRunnerScript = preload("res://scripts/careers/jigsaw_route_runner.gd")

func _init() -> void:
	print("==================================================")
	print("  MILESTONE M2 VERIFICATION: VEHICLES & CITY MAP")
	print("==================================================")

	_test_vehicle_controller()
	_test_taxi_sedan_scene()
	_test_delivery_bicycle_scene()
	_test_jigsaw_route_runner()
	_test_downtown_map_expansion()

	print("\n--------------------------------------------------")
	print("M2 RESULTS: %d PASSED, %d FAILED" % [tests_passed, tests_failed])
	print("--------------------------------------------------")

	if tests_failed == 0:
		print(">> MILESTONE M2 ALL CHECKS PASSED CLEANLY! <<\n")
		quit(0)
	else:
		printerr(">> MILESTONE M2 HAD FAILURES! <<\n")
		quit(1)

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		print("  [PASS] %s" % test_name)
		tests_passed += 1
	else:
		printerr("  [FAIL] %s" % test_name)
		tests_failed += 1

func _test_vehicle_controller() -> void:
	print("\n[M2 Suite 1: VehicleController Script & Mechanics]")
	var vc := VehicleControllerScript.new() as VehicleController
	root.add_child(vc)

	# Verify export specs
	_assert(vc.vehicle_name == "Yellow-Top Taxi", "Default vehicle_name is Yellow-Top Taxi")
	_assert(is_equal_approx(vc.max_speed, 16.0), "Default max_speed is 16.0 m/s (~58 km/h)")
	_assert(is_equal_approx(vc.acceleration, 8.0), "Default acceleration is 8.0 m/s^2")
	_assert(is_equal_approx(vc.braking, 14.0), "Default braking is 14.0 m/s^2")
	_assert(is_equal_approx(vc.reverse_speed, 6.0), "Default reverse_speed is 6.0 m/s")
	_assert(is_equal_approx(vc.steering_speed, 2.2), "Default steering_speed is 2.2 rad/s")
	_assert(is_equal_approx(vc.max_steering_angle, 0.55), "Default max_steering_angle is 0.55 rad")
	_assert(is_equal_approx(vc.fuel_capacity, 50.0), "Default fuel_capacity is 50.0 L")
	_assert(is_equal_approx(vc.fuel_consumption_rate, 0.05), "Default fuel_consumption_rate is 0.05 L/s")
	_assert(vc.is_motorized == true, "Default is_motorized is true")

	# Verify state variables
	_assert(is_equal_approx(vc.current_speed, 0.0), "Initial current_speed is 0.0")
	_assert(is_equal_approx(vc.current_steering, 0.0), "Initial current_steering is 0.0")
	_assert(is_equal_approx(vc.current_fuel, 50.0), "Initial current_fuel is 50.0")
	_assert(vc.is_driven == false, "Initial is_driven is false")
	_assert(vc.driver_node == null, "Initial driver_node is null")
	_assert(vc.taxi_meter_active == false, "Initial taxi_meter_active is false")
	_assert(is_equal_approx(vc.trip_distance, 0.0), "Initial trip_distance is 0.0")
	_assert(vc.trip_fare == 0, "Initial trip_fare is 0")

	# Verify collision layer 3 (Vehicles = 4) and mask (World 1 | Vehicles 4 = 5)
	_assert(vc.get_collision_layer_value(3) == true, "Collision layer value 3 (Vehicles) is true")
	_assert(vc.get_collision_mask_value(1) == true, "Collision mask value 1 (World) is true")
	_assert(vc.get_collision_mask_value(3) == true, "Collision mask value 3 (Vehicles) is true")

	# Test signals exist
	_assert(vc.has_signal("driver_entered"), "Has driver_entered signal")
	_assert(vc.has_signal("driver_exited"), "Has driver_exited signal")
	_assert(vc.has_signal("fuel_changed"), "Has fuel_changed signal")
	_assert(vc.has_signal("fare_updated"), "Has fare_updated signal")

	# Test enter and exit vehicle
	var dummy_driver := Node3D.new()
	dummy_driver.name = "TestPlayer"
	root.add_child(dummy_driver)

	var entered_signal_fired: Array[bool] = [false]
	vc.driver_entered.connect(func(_d: Node3D): entered_signal_fired[0] = true)

	var enter_res: bool = vc.enter_vehicle(dummy_driver)
	_assert(enter_res == true, "enter_vehicle succeeded")
	_assert(vc.is_driven == true, "is_driven is true after embark")
	_assert(vc.driver_node == dummy_driver, "driver_node set to driver")
	_assert(entered_signal_fired[0] == true, "driver_entered signal emitted")
	_assert(dummy_driver.visible == false, "driver hidden while inside vehicle")

	# Cannot enter if already driven
	var second_driver := Node3D.new()
	_assert(vc.enter_vehicle(second_driver) == false, "Cannot enter vehicle already driven")
	second_driver.free()

	# Test exit vehicle
	var exited_signal_fired: Array[bool] = [false]
	vc.driver_exited.connect(func(): exited_signal_fired[0] = true)

	vc.exit_vehicle()
	_assert(vc.is_driven == false, "is_driven is false after disembark")
	_assert(vc.driver_node == null, "driver_node cleared")
	_assert(dummy_driver.visible == true, "driver visible after exit")
	_assert(exited_signal_fired[0] == true, "driver_exited signal emitted")

	dummy_driver.free()

	# Test refuel logic
	vc.current_fuel = 30.0
	var added: float = vc.refuel(15.0)
	_assert(is_equal_approx(added, 15.0), "Refueled 15.0 L")
	_assert(is_equal_approx(vc.current_fuel, 45.0), "Current fuel updated to 45.0 L")

	var overflow: float = vc.refuel(20.0) # only 5.0 L space remains
	_assert(is_equal_approx(overflow, 5.0), "Refuel capped at capacity (added 5.0 L)")
	_assert(is_equal_approx(vc.current_fuel, 50.0), "Fuel reaches exact capacity 50.0 L")

	# Test taxi meter
	vc.start_taxi_meter()
	_assert(vc.taxi_meter_active == true, "Taxi meter active")
	_assert(vc.trip_fare == 1500, "Base taxi fare is 1500 MMK")
	_assert(is_equal_approx(vc.trip_distance, 0.0), "Initial trip distance is 0.0m")

	# Simulate 1000m driven
	vc.trip_distance = 1000.0
	vc.trip_fare = 1500 + int(1000.0 * 1.2) # 1500 + 1200 = 2700
	var collected: int = vc.stop_taxi_meter()
	_assert(vc.taxi_meter_active == false, "Taxi meter stopped")
	_assert(collected == 2700, "Collected fare is 2,700 MMK for 1km (1500 base + 1200 distance)")

	# Test get_save_data / load_save_data
	var sdata: Dictionary = vc.get_save_data()
	_assert(sdata.has("vehicle_name"), "Save data has vehicle_name")
	_assert(sdata.has("current_fuel"), "Save data has current_fuel")

	vc.load_save_data({"current_fuel": 25.5, "trip_distance": 500.0, "trip_fare": 2100})
	_assert(is_equal_approx(vc.current_fuel, 25.5), "Restored current_fuel from save")
	_assert(is_equal_approx(vc.trip_distance, 500.0), "Restored trip_distance from save")
	_assert(vc.trip_fare == 2100, "Restored trip_fare from save")

	vc.free()

func _test_taxi_sedan_scene() -> void:
	print("\n[M2 Suite 2: TaxiSedan Scene Composition]")
	var scene: PackedScene = load("res://scenes/vehicles/taxi_sedan.tscn")
	_assert(scene != null, "scenes/vehicles/taxi_sedan.tscn loaded successfully")
	var taxi := scene.instantiate() as CharacterBody3D
	_assert(taxi != null, "TaxiSedan instantiated as CharacterBody3D")
	_assert(taxi is VehicleController, "TaxiSedan script is VehicleController")
	_assert(taxi.vehicle_name == "Yellow-Top Taxi", "Taxi name is Yellow-Top Taxi")
	_assert(taxi.is_motorized == true, "Taxi is motorized")

	# Check collision shape
	var col := taxi.get_node_or_null("CollisionShape3D") as CollisionShape3D
	_assert(col != null, "Taxi has CollisionShape3D")
	_assert(col.shape is BoxShape3D, "Collision shape is BoxShape3D")
	var box := col.shape as BoxShape3D
	_assert(is_equal_approx(box.size.x, 1.8) and is_equal_approx(box.size.y, 1.4) and is_equal_approx(box.size.z, 4.2), "BoxShape3D size is (1.8, 1.4, 4.2)")

	# Check visual meshes
	_assert(taxi.has_node("CarBody"), "Taxi has CarBody mesh")
	_assert(taxi.has_node("Cabin"), "Taxi has Cabin mesh")
	_assert(taxi.has_node("TaxiSign"), "Taxi has TaxiSign mesh")
	_assert(taxi.has_node("TaxiSign/Label3D"), "TaxiSign has Label3D 'TAXI'")
	_assert(taxi.has_node("Wheel_FL"), "Taxi has Wheel_FL")
	_assert(taxi.has_node("Wheel_FR"), "Taxi has Wheel_FR")
	_assert(taxi.has_node("Wheel_RL"), "Taxi has Wheel_RL")
	_assert(taxi.has_node("Wheel_RR"), "Taxi has Wheel_RR")
	_assert(taxi.has_node("Light_L"), "Taxi has Light_L")
	_assert(taxi.has_node("Light_R"), "Taxi has Light_R")

	# Check DoorArea and ExitPoint
	var door := taxi.get_node_or_null("DoorArea") as Area3D
	_assert(door != null, "Taxi has DoorArea")
	_assert(door.get_collision_layer_value(4) == true, "DoorArea is on Layer 4 (Interactables)")
	_assert(door.get_collision_mask_value(2) == true, "DoorArea monitors Layer 2 (Characters)")

	var exit := taxi.get_node_or_null("ExitPoint")
	_assert(exit != null, "Taxi has ExitPoint marker")

	# Check vehicular chase camera
	_assert(taxi.has_node("CameraMount"), "Taxi has CameraMount")
	var spring_arm := taxi.get_node_or_null("CameraMount/SpringArm3D") as SpringArm3D
	_assert(spring_arm != null, "CameraMount has SpringArm3D")
	_assert(is_equal_approx(spring_arm.spring_length, 6.0), "SpringArm length is 6.0m")
	var cam := taxi.get_node_or_null("CameraMount/SpringArm3D/Camera3D") as Camera3D
	_assert(cam != null, "SpringArm has Camera3D")
	_assert(is_equal_approx(cam.fov, 75.0), "Camera3D fov is 75")
	_assert(cam.current == false, "Camera3D initially inactive until driven")

	taxi.free()

func _test_delivery_bicycle_scene() -> void:
	print("\n[M2 Suite 3: DeliveryBicycle Scene Composition]")
	var scene: PackedScene = load("res://scenes/vehicles/delivery_bicycle.tscn")
	_assert(scene != null, "scenes/vehicles/delivery_bicycle.tscn loaded successfully")
	var bike := scene.instantiate() as CharacterBody3D
	_assert(bike != null, "DeliveryBicycle instantiated as CharacterBody3D")
	_assert(bike is VehicleController, "DeliveryBicycle script is VehicleController")
	_assert(bike.vehicle_name == "Delivery Bicycle", "Vehicle name is Delivery Bicycle")
	_assert(bike.is_motorized == false, "Bicycle is not motorized")
	_assert(is_equal_approx(bike.max_speed, 7.0), "Bicycle max_speed is 7.0 m/s")
	_assert(is_equal_approx(bike.acceleration, 4.0), "Bicycle acceleration is 4.0 m/s^2")
	_assert(is_equal_approx(bike.fuel_capacity, 0.0), "Bicycle fuel_capacity is 0.0")

	# Visual components
	_assert(bike.has_node("Frame"), "Bicycle has Frame mesh")
	_assert(bike.has_node("Wheel_F"), "Bicycle has front wheel")
	_assert(bike.has_node("Wheel_R"), "Bicycle has rear wheel")
	_assert(bike.has_node("Handlebars"), "Bicycle has Handlebars")
	_assert(bike.has_node("CargoBasket"), "Bicycle has CargoBasket")

	# Interaction & Exit
	_assert(bike.has_node("DoorArea"), "Bicycle has DoorArea")
	_assert(bike.has_node("ExitPoint"), "Bicycle has ExitPoint")
	_assert(bike.has_node("CameraMount/SpringArm3D/Camera3D"), "Bicycle has chase camera")

	bike.free()

func _test_jigsaw_route_runner() -> void:
	print("\n[M2 Suite 4: JigsawRouteRunner Feeder Transit System]")
	var runner := JigsawRouteRunnerScript.new() as JigsawRouteRunner
	root.add_child(runner)

	var stops: Array[Dictionary] = runner.get_stops()
	_assert(stops.size() == 4, "Route has 4 downtown stops")
	_assert(stops[0].get("name") == "Sule Roundabout (Origin)", "Stop 0 is Sule Roundabout (Origin)")
	_assert(stops[1].get("name") == "Maha Bandula Park East", "Stop 1 is Maha Bandula Park East")
	_assert(stops[2].get("name") == "Botahtaung Jetty Approach", "Stop 2 is Botahtaung Jetty Approach")
	_assert(stops[3].get("name") == "Chinatown Market Junction", "Stop 3 is Chinatown Market Junction")

	# Start route
	_assert(runner.is_active == false, "Initially inactive")
	runner.start_route()
	_assert(runner.is_active == true, "Route active after start_route()")
	_assert(runner.current_stop_index == 0, "Current stop index is 0")
	_assert(runner.get_current_stop_name() == "Sule Roundabout (Origin)", "Current stop is Sule Roundabout")
	_assert(is_equal_approx(runner.get_route_progress(), 0.0), "Initial route progress is 0.0")

	# Reach stops sequentially
	var earnings_0: int = runner.reach_stop(0)
	_assert(earnings_0 > 0, "Stop 0 generated earnings (passengers boarded)")
	_assert(runner.current_stop_index == 1, "Advanced to stop index 1")
	_assert(is_equal_approx(runner.get_route_progress(), 0.25), "Route progress is 0.25 (1/4)")
	_assert(runner.get_current_stop_name() == "Maha Bandula Park East", "Next stop is Maha Bandula Park East")

	var earnings_1: int = runner.reach_stop(1)
	_assert(earnings_1 > 0, "Stop 1 generated earnings")
	_assert(is_equal_approx(runner.get_route_progress(), 0.5), "Route progress is 0.5 (2/4)")

	var earnings_2: int = runner.reach_stop(2)
	_assert(earnings_2 > 0, "Stop 2 generated earnings")
	_assert(is_equal_approx(runner.get_route_progress(), 0.75), "Route progress is 0.75 (3/4)")

	var earnings_3: int = runner.reach_stop(3)
	_assert(earnings_3 > 0, "Stop 3 generated earnings")
	_assert(is_equal_approx(runner.get_route_progress(), 1.0), "Route progress is 1.0 (4/4)")

	# Complete route
	var bonus: int = runner.complete_route()
	_assert(bonus >= 3500, "Route completion bonus awarded (>= 3,500 MMK)")
	_assert(runner.is_active == false, "Route marked inactive after completion")
	_assert(runner.get_current_stop_name() == "Route Complete", "Status reports Route Complete")

	runner.free()

func _test_downtown_map_expansion() -> void:
	print("\n[M2 Suite 5: Downtown Yangon Map Expansion & Landmarks]")
	var world_scene: PackedScene = load("res://scenes/world/downtown_yangon.tscn")
	_assert(world_scene != null, "scenes/world/downtown_yangon.tscn loaded")
	var world := world_scene.instantiate() as Node3D
	_assert(world != null, "DowntownYangon instantiated")

	# 1. Sule Pagoda Landmark
	var sule: StaticBody3D = world.get_node_or_null("SulePagoda") as StaticBody3D
	_assert(sule != null, "SulePagoda landmark exists")
	_assert(sule.collision_layer == 1, "SulePagoda is on Layer 1 (World)")
	_assert(sule.has_node("Base"), "SulePagoda has Base mesh")
	_assert(sule.has_node("StupaMiddle"), "SulePagoda has StupaMiddle mesh")
	_assert(sule.has_node("Spire"), "SulePagoda has Spire mesh")
	_assert(sule.has_node("CollisionShape3D"), "SulePagoda has CollisionShape3D")

	# 2. City Hall Landmark
	var city_hall: StaticBody3D = world.get_node_or_null("CityHall") as StaticBody3D
	_assert(city_hall != null, "CityHall landmark exists")
	_assert(city_hall.collision_layer == 1, "CityHall is on Layer 1 (World)")
	_assert(city_hall.has_node("MainBuilding"), "CityHall has MainBuilding mesh")
	_assert(city_hall.has_node("CentralTower"), "CityHall has CentralTower mesh")
	_assert(city_hall.has_node("PeacockArch"), "CityHall has PeacockArch motif")
	_assert(is_equal_approx(city_hall.position.x, 30.0) and is_equal_approx(city_hall.position.z, -50.0), "CityHall located at (30, 0, -50)")

	# 3. Maha Bandula Park & Independence Monument
	var park: Node3D = world.get_node_or_null("Park")
	_assert(park != null, "Park node exists")
	_assert(park.has_node("ParkGround"), "Park has ParkGround")
	_assert(park.has_node("ParkBench"), "Park has ParkBench")
	_assert(park.has_node("IndependenceMonument"), "Park has IndependenceMonument obelisk")
	_assert(park.has_node("GravelPathNS"), "Park has Gravel paths")

	# 4. Roads & Sule Roundabout
	var roads: Node3D = world.get_node_or_null("Roads")
	_assert(roads != null, "Roads node exists")
	_assert(roads.has_node("MainRoad_NS"), "MainRoad_NS exists")
	_assert(roads.has_node("MainRoad_EW"), "MainRoad_EW exists")
	_assert(roads.has_node("SideStreet1"), "SideStreet1 exists")
	_assert(roads.has_node("SideStreet2"), "SideStreet2 exists")
	_assert(roads.has_node("SuleRoundabout"), "Roads has SuleRoundabout encircling Sule Pagoda")

	# 5. Gas Station & Gas Pump
	var gas_pump: Area3D = world.get_node_or_null("Interactables/GasPump") as Area3D
	_assert(gas_pump != null, "Interactables/GasPump exists")
	_assert(gas_pump.get_collision_layer_value(4) == true, "GasPump is on Layer 4 (Interactables)")
	_assert(gas_pump.has_node("CollisionShape3D"), "GasPump has CollisionShape3D")
	_assert(gas_pump.has_node("MeshInstance3D"), "GasPump has MeshInstance3D")
	_assert(gas_pump.has_node("GasPumpHandler"), "GasPump has GasPumpHandler script")

	# 6. Parked Vehicles
	var taxi_inst := world.get_node_or_null("TaxiSedan")
	_assert(taxi_inst != null, "TaxiSedan parked instance exists")
	_assert(taxi_inst is VehicleController, "TaxiSedan is VehicleController")
	_assert(is_equal_approx(taxi_inst.position.x, 12.0) and is_equal_approx(taxi_inst.position.z, -10.0), "TaxiSedan parked near Sule Stand at (12, 0.2, -10)")

	var bike_inst := world.get_node_or_null("DeliveryBicycle")
	_assert(bike_inst != null, "DeliveryBicycle parked instance exists")
	_assert(bike_inst is VehicleController, "DeliveryBicycle is VehicleController")
	_assert(is_equal_approx(bike_inst.position.x, 18.0) and is_equal_approx(bike_inst.position.z, 8.0), "DeliveryBicycle parked near Tea Shop at (18, 0.2, 8)")

	world.free()
