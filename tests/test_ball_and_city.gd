class_name TestBallAndCity
extends Node

## Automated test suite for:
## 1. 3D Ball Player Character (SphereMesh, custom colors, photo upload support, overhead nametag).
## 2. Full-scale Downtown Yangon map expansion (600x600m, Chinatown, Secretariat, Theingyi, Strand, Railway).
## 3. Real-time GPS Minimap radar with district tracking and zoom.
## 4. Mobile virtual on-screen keypad and touch controls.
## 5. Drivable Yangon Motorcycle scene and riding mechanics.

const HUDMinimap = preload("res://scripts/ui/hud_minimap.gd")
const MobileKeypad = preload("res://scripts/ui/mobile_keypad.gd")

var tests_passed: int = 0
var tests_failed: int = 0

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		print("  [PASS] %s" % test_name)
		tests_passed += 1
	else:
		printerr("  [FAIL] %s" % test_name)
		tests_failed += 1

func run_all() -> void:
	print("\n==================================================")
	print("  [Suite 21: 3D Ball Avatar, Yangon City & Vehicles]")
	print("==================================================")

	_test_player_ball_avatar()
	_test_motorcycle_vehicle()
	_test_gps_minimap_and_keypad()
	_test_expanded_city_landmarks()

func _test_player_ball_avatar() -> void:
	print("\n[Ball Sub-Suite 1: 3D Ball Character & Overhead Nametag]")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	_assert(player_scene != null, "player.tscn loaded successfully")
	var player := player_scene.instantiate() as ThirdPersonController
	add_child(player)

	_assert(player.has_node("PlayerBall"), "Player has PlayerBall MeshInstance3D")
	var ball_mesh := player.get_node("PlayerBall") as MeshInstance3D
	_assert(ball_mesh.mesh is SphereMesh, "PlayerBall mesh is a 3D SphereMesh")

	_assert(player.has_node("OverheadLabel"), "Player has persistent OverheadLabel Label3D")
	var label := player.get_node("OverheadLabel") as Label3D
	_assert(label.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "OverheadLabel billboard is enabled")
	_assert(label.no_depth_test == true, "OverheadLabel visible through buildings (no_depth_test)")

	# Test custom color assignment
	player.set_ball_color(Color(0.88, 0.12, 0.25)) # Ruby red
	_assert(player.ball_color == Color(0.88, 0.12, 0.25), "set_ball_color updated ball_color")

	# Test custom nametag update
	player.set_player_name("Ko Phyo", "Motorcycle Courier")
	_assert(label.text.contains("Ko Phyo"), "OverheadLabel reflects updated name 'Ko Phyo'")
	_assert(label.text.contains("Motorcycle Courier"), "OverheadLabel reflects updated role")

	# Test save/load serialization of 3D ball
	var save_data := player.get_save_data()
	_assert(save_data.has("ball_color"), "get_save_data includes ball_color")
	_assert(save_data.has("character_name"), "get_save_data includes character_name")

	player.load_save_data({
		"ball_color": Color(0.12, 0.68, 0.35).to_html(), # Jade
		"character_name": "Ma Thida",
		"character_role": "Tea Host"
	})
	_assert(player.character_name == "Ma Thida", "load_save_data restored citizen name 'Ma Thida'")
	_assert(label.text.contains("Ma Thida"), "OverheadLabel restored 'Ma Thida'")

	player.queue_free()

func _test_motorcycle_vehicle() -> void:
	print("\n[Ball Sub-Suite 2: Drivable Motorcycle Scene & Physics]")
	var moto_scene: PackedScene = load("res://scenes/vehicles/motorcycle.tscn")
	_assert(moto_scene != null, "scenes/vehicles/motorcycle.tscn loaded successfully")
	var moto := moto_scene.instantiate() as VehicleController
	add_child(moto)

	_assert(moto.vehicle_name == "Yangon Motorcycle", "Vehicle name is 'Yangon Motorcycle'")
	_assert(moto.max_speed >= 16.0, "Motorcycle max_speed is agile (>= 16.0 m/s)")
	_assert(moto.is_motorized == true, "Motorcycle is motorized")
	_assert(moto.fuel_capacity >= 10.0, "Motorcycle fuel_capacity >= 10.0 L")
	_assert(moto.has_node("DoorArea"), "Motorcycle has DoorArea interaction zone")
	_assert(moto.has_node("ExitPoint"), "Motorcycle has ExitPoint marker")
	_assert(moto.has_node("CameraMount/SpringArm3D/Camera3D"), "Motorcycle has chase camera")

	# Test embarking onto motorcycle
	var test_driver := Node3D.new()
	test_driver.name = "TestBallDriver"
	add_child(test_driver)

	var embarked: bool = moto.enter_vehicle(test_driver)
	_assert(embarked == true, "enter_vehicle embarked player onto motorcycle")
	_assert(moto.is_driven == true, "Motorcycle is_driven is true")
	_assert(test_driver.visible == false, "Driver hidden while riding motorcycle")

	# Test disembarking from motorcycle
	moto.exit_vehicle()
	_assert(moto.is_driven == false, "Motorcycle is_driven is false after exit")
	_assert(test_driver.visible == true, "Driver restored visible after exit")

	test_driver.queue_free()
	moto.queue_free()

func _test_gps_minimap_and_keypad() -> void:
	print("\n[Ball Sub-Suite 3: GPS Minimap Radar & Mobile Touch Keypad]")
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	_assert(hud_scene != null, "scenes/ui/hud.tscn loaded successfully")
	var hud := hud_scene.instantiate() as CanvasLayer
	add_child(hud)

	var minimap: HUDMinimap = hud.find_child("MinimapRadar", true, false) as HUDMinimap
	_assert(minimap != null, "HUD contains MinimapRadar control")

	# Test district name spatial lookups
	_assert(minimap.get_district_name(Vector3(0, 0, 0)) == "Sule Pagoda Central Plaza", "Center pos is Sule Pagoda Plaza")
	_assert(minimap.get_district_name(Vector3(-120, 0, 30)) == "Chinatown & 19th St Night Market", "(-120, 30) is Chinatown")
	_assert(minimap.get_district_name(Vector3(-120, 0, -80)) == "Theingyi Zei Wholesale Bazaar", "(-120, -80) is Theingyi Zei")
	_assert(minimap.get_district_name(Vector3(120, 0, -60)) == "Secretariat Heritage Complex", "(120, -60) is Secretariat")
	_assert(minimap.get_district_name(Vector3(0, 0, 220)) == "Strand Riverfront & Ferry Jetty", "(0, 220) is Strand Riverfront")
	_assert(minimap.get_district_name(Vector3(0, 0, -200)) == "Central Railway District", "(0, -200) is Railway District")

	# Test zoom toggle
	var initial_zoom: float = minimap.radar_radius
	var next_zoom: float = minimap.toggle_zoom()
	_assert(next_zoom != initial_zoom, "Minimap toggle_zoom switched radar radius")

	# Test MobileKeypad component
	var keypad: MobileKeypad = hud.find_child("MobileKeypad", true, false) as MobileKeypad
	_assert(keypad != null, "HUD contains MobileKeypad virtual touch overlay")
	_assert(keypad.has_node("DPad/BtnUp"), "Keypad has DPad BtnUp")
	_assert(keypad.has_node("DPad/BtnDown"), "Keypad has DPad BtnDown")
	_assert(keypad.has_node("DPad/BtnLeft"), "Keypad has DPad BtnLeft")
	_assert(keypad.has_node("DPad/BtnRight"), "Keypad has DPad BtnRight")
	_assert(keypad.has_node("ActionGroup/BtnInteract"), "Keypad has ActionGroup BtnInteract")
	_assert(keypad.has_node("ActionGroup/BtnRide"), "Keypad has ActionGroup BtnRide")

	var is_vis_before: bool = keypad.visible
	var toggled: bool = keypad.toggle_keypad()
	_assert(toggled != is_vis_before, "toggle_keypad successfully toggles keypad visibility")

	hud.queue_free()

func _test_expanded_city_landmarks() -> void:
	print("\n[Ball Sub-Suite 4: Expanded City Scale & New Landmarks]")
	var world_scene: PackedScene = load("res://scenes/world/downtown_yangon.tscn")
	_assert(world_scene != null, "downtown_yangon.tscn loaded")
	var world := world_scene.instantiate() as Node3D
	add_child(world)

	_assert(world.has_node("ChinatownDistrict"), "World contains ChinatownDistrict landmark")
	_assert(world.has_node("TheingyiZeiBazaar"), "World contains TheingyiZeiBazaar landmark")
	_assert(world.has_node("SecretariatHeritage"), "World contains SecretariatHeritage landmark")
	_assert(world.has_node("StrandRiverfront"), "World contains StrandRiverfront landmark")
	_assert(world.has_node("CentralRailwayStation"), "World contains CentralRailwayStation landmark")

	# Check vehicles parked across Yangon
	_assert(world.has_node("TaxiSedan"), "World contains parked TaxiSedan near Sule")
	_assert(world.has_node("DeliveryBicycle"), "World contains parked DeliveryBicycle")
	_assert(world.has_node("Motorcycle_Chinatown"), "World contains parked Motorcycle at Chinatown")
	_assert(world.has_node("Motorcycle_Strand"), "World contains parked Motorcycle at Strand Riverfront")
	_assert(world.has_node("Taxi_RailwayStation"), "World contains parked Taxi at Railway Station")

	world.queue_free()
