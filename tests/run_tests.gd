extends SceneTree
## Comprehensive Headless Test Suite for Yangon Life (ရန်ကုန် ဘဝ)
## Verifies all core systems: Economy, Needs, Time, Careers, Interaction, Player, World, HUD, MainGame, Save/Load

var tests_passed: int = 0
var tests_failed: int = 0

const GameManagerScript = preload("res://scripts/systems/game_manager.gd")
const EconomyManagerScript = preload("res://scripts/economy/economy_manager.gd")
const NeedsManagerScript = preload("res://scripts/simulation/needs_manager.gd")
const TimeManagerScript = preload("res://scripts/simulation/time_manager.gd")
const SaveManagerScript = preload("res://scripts/save/save_manager.gd")
const CareerManagerScript = preload("res://scripts/careers/career_manager.gd")
const InteractionManagerScript = preload("res://scripts/interaction/interaction_manager.gd")
const InteractableZoneScript = preload("res://scripts/interaction/interactable_zone.gd")
const FoodStallHandlerScript = preload("res://scripts/interaction/food_stall_handler.gd")
const TeaShopHandlerScript = preload("res://scripts/interaction/tea_shop_handler.gd")
const JobBoardHandlerScript = preload("res://scripts/interaction/job_board_handler.gd")
const ParkBenchHandlerScript = preload("res://scripts/interaction/park_bench_handler.gd")
const SkillManagerScript = preload("res://scripts/skills/skill_manager.gd")
const InventoryManagerScript = preload("res://scripts/inventory/inventory_manager.gd")
const HousingManagerScript = preload("res://scripts/housing/housing_manager.gd")
const DeliveryRunnerScript = preload("res://scripts/careers/delivery_runner.gd")
const StreetVendorRunnerScript = preload("res://scripts/careers/street_vendor_runner.gd")
const TaxiShiftRunnerScript = preload("res://scripts/careers/taxi_shift_runner.gd")
const NPCPedestrianScript = preload("res://scripts/npcs/npc_pedestrian.gd")
const TrafficCarScript = preload("res://scripts/vehicles/traffic_car.gd")
const WeatherControllerScript = preload("res://scripts/simulation/weather_controller.gd")
const TestM5UISuiteScript = preload("res://tests/test_m5_ui_suite.gd")
const TestM7PolishSuiteScript = preload("res://tests/test_m7_polish_suite.gd")
const TestBallAndCityScript = preload("res://tests/test_ball_and_city.gd")

var _gm: Node
var _em: Node
var _nm: Node
var _tm: Node
var _sm: Node
var _cm: Node
var _im: Node
var _skm: Node
var _inm: Node
var _hsm: Node

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
	# Ensure root has singletons initialized for test environment
	if not root.has_node("GameManager"):
		_gm = GameManagerScript.new()
		_gm.name = "GameManager"
		root.add_child(_gm)
	else:
		_gm = root.get_node("GameManager")

	if not root.has_node("EconomyManager"):
		_em = EconomyManagerScript.new()
		_em.name = "EconomyManager"
		root.add_child(_em)
	else:
		_em = root.get_node("EconomyManager")

	if not root.has_node("NeedsManager"):
		_nm = NeedsManagerScript.new()
		_nm.name = "NeedsManager"
		root.add_child(_nm)
	else:
		_nm = root.get_node("NeedsManager")

	if not root.has_node("TimeManager"):
		_tm = TimeManagerScript.new()
		_tm.name = "TimeManager"
		root.add_child(_tm)
	else:
		_tm = root.get_node("TimeManager")

	if not root.has_node("CareerManager"):
		_cm = CareerManagerScript.new()
		_cm.name = "CareerManager"
		root.add_child(_cm)
	else:
		_cm = root.get_node("CareerManager")

	if not root.has_node("InteractionManager"):
		_im = InteractionManagerScript.new()
		_im.name = "InteractionManager"
		root.add_child(_im)
	else:
		_im = root.get_node("InteractionManager")

	if not root.has_node("SaveManager"):
		_sm = SaveManagerScript.new()
		_sm.name = "SaveManager"
		root.add_child(_sm)
	else:
		_sm = root.get_node("SaveManager")

	if not root.has_node("SkillManager"):
		_skm = SkillManagerScript.new()
		_skm.name = "SkillManager"
		root.add_child(_skm)
	else:
		_skm = root.get_node("SkillManager")

	if not root.has_node("InventoryManager"):
		_inm = InventoryManagerScript.new()
		_inm.name = "InventoryManager"
		root.add_child(_inm)
	else:
		_inm = root.get_node("InventoryManager")

	if not root.has_node("HousingManager"):
		_hsm = HousingManagerScript.new()
		_hsm.name = "HousingManager"
		root.add_child(_hsm)
	else:
		_hsm = root.get_node("HousingManager")

func _run_all_tests() -> void:
	print("==================================================")
	print("  YANGON LIFE (ရန်ကုန် ဘဝ) — AUTOMATED HEADLESS TESTS")
	print("==================================================")

	_setup_autoloads()

	_test_game_manager()
	_test_economy_manager()
	_test_needs_manager()
	_test_time_manager()
	_test_career_manager()
	_test_interaction_system()
	_test_player_character()
	_test_downtown_world()
	_test_hud_ui()
	_test_main_game_scene()
	_test_save_load_system()
	_test_skill_manager()
	_test_inventory_manager()
	_test_housing_manager()
	_test_delivery_runner()
	_test_street_vendor_runner()
	_test_taxi_shift_runner()
	_test_m4_living_city_systems()
	_test_m5_ui_suite()
	_test_m7_polish_suite()
	_test_ball_and_city()

	print("\n--------------------------------------------------")
	print("TEST RESULTS: %d PASSED, %d FAILED" % [tests_passed, tests_failed])
	print("--------------------------------------------------")

	if tests_failed == 0:
		print(">> ALL SYSTEMS VERIFIED CLEANLY WITH 0 ERRORS! <<\n")
		quit(0)
	else:
		printerr(">> SOME TESTS FAILED! <<\n")
		quit(1)

func _test_game_manager() -> void:
	print("\n[Suite 1: GameManager & Input Actions]")
	_assert(InputMap.has_action("move_forward"), "Input action move_forward registered")
	_assert(InputMap.has_action("move_backward"), "Input action move_backward registered")
	_assert(InputMap.has_action("move_left"), "Input action move_left registered")
	_assert(InputMap.has_action("move_right"), "Input action move_right registered")
	_assert(InputMap.has_action("sprint"), "Input action sprint registered")
	_assert(InputMap.has_action("jump"), "Input action jump registered")
	_assert(InputMap.has_action("interact"), "Input action interact registered")
	_assert(InputMap.has_action("inventory"), "Input action inventory registered")
	_assert(InputMap.has_action("map"), "Input action map registered")
	_assert(InputMap.has_action("phone"), "Input action phone registered")
	_assert(InputMap.has_action("enter_vehicle"), "Input action enter_vehicle registered")

	_assert(_gm.is_paused == false, "Game initially not paused")
	_gm.toggle_pause()
	_assert(_gm.is_paused == true, "toggle_pause pauses game")
	_gm.toggle_pause()
	_assert(_gm.is_paused == false, "toggle_pause resumes game")

func _test_economy_manager() -> void:
	print("\n[Suite 2: EconomyManager & MMK Wallet]")
	_em.set_balance(50000)
	_assert(_em.get_balance() == 50000, "Starting balance is 50,000 MMK")
	_assert(_em.can_afford(3000) == true, "Can afford 3,000 MMK meal")
	_assert(_em.can_afford(60000) == false, "Cannot afford 60,000 MMK when balance is 50,000")

	var spent: bool = _em.spend_money(3000, "Lunch")
	_assert(spent == true, "spend_money succeeds when affordable")
	_assert(_em.get_balance() == 47000, "Balance correctly deducted to 47,000 MMK")

	var overdraft: bool = _em.spend_money(100000, "Expensive item")
	_assert(overdraft == false, "Overdraft rejected (spend_money returned false)")
	_assert(_em.get_balance() == 47000, "Balance unchanged after rejected overdraft")

	_em.add_money(8000, "Shift wage")
	_assert(_em.get_balance() == 55000, "Shift wage credited (47,000 + 8,000 = 55,000 MMK)")

	var econ_data: Dictionary = _em.get_save_data()
	_assert(econ_data.get("balance") == 55000, "get_save_data exports correct balance")
	_em.load_save_data({"balance": 50000})
	_assert(_em.get_balance() == 50000, "load_save_data restored balance to 50,000 MMK")

func _test_needs_manager() -> void:
	print("\n[Suite 3: NeedsManager & Life Simulation]")
	_nm.hunger = 80.0
	_nm.energy = 100.0
	_nm.hygiene = 90.0
	_nm.stress = 10.0

	_assert(_nm.can_sprint() == true, "can_sprint is true when energy is 100")
	_nm.energy = 10.0
	_assert(_nm.can_sprint() == false, "can_sprint is false when energy < 15")
	_nm.rest(50.0)
	_assert(is_equal_approx(_nm.energy, 60.0), "rest restores energy to 60")

	_nm.hunger = 40.0
	_nm.eat(30.0)
	_assert(is_equal_approx(_nm.hunger, 70.0), "eat restores hunger to 70")

	_nm.hygiene = 50.0
	_nm.bathe(40.0)
	_assert(is_equal_approx(_nm.hygiene, 90.0), "bathe restores hygiene to 90")

	_nm.stress = 40.0
	_nm.relax(20.0)
	_assert(is_equal_approx(_nm.stress, 20.0), "relax reduces stress to 20")

	var eff: float = _nm.get_work_efficiency()
	_assert(eff > 0.8, "Work efficiency is healthy when needs are satisfied")

	_nm.hunger = 10.0
	_nm.energy = 10.0
	_nm.stress = 90.0
	var poor_eff: float = _nm.get_work_efficiency()
	_assert(poor_eff < 0.5, "Work efficiency penalized heavily when needs are critical")

	# Reset to healthy defaults
	_nm.hunger = 80.0
	_nm.energy = 100.0
	_nm.hygiene = 90.0
	_nm.stress = 10.0

func _test_time_manager() -> void:
	print("\n[Suite 4: TimeManager & Game Clock]")
	_tm.set_time(8, 0, 1)
	_assert(_tm.game_hour == 8 and _tm.game_minute == 0, "Initial time is 08:00")
	_assert(_tm.game_day == 1, "Initial day is 1")
	_assert(_tm.get_time_string() == "08:00", "get_time_string returns '08:00'")
	_assert(_tm.get_day_period() == "morning", "08:00 is 'morning'")
	_assert(_tm.is_daytime() == true, "08:00 is daytime")

	_tm.advance_time(150) # 2 hours 30 mins -> 10:30
	_assert(_tm.game_hour == 10 and _tm.game_minute == 30, "advance_time(150) advances to 10:30")
	_assert(_tm.get_time_string() == "10:30", "get_time_string returns '10:30'")

	_tm.set_time(23, 50, 1)
	_tm.advance_time(20) # cross midnight
	_assert(_tm.game_hour == 0 and _tm.game_minute == 10, "Midnight transition advances hour to 00:10")
	_assert(_tm.game_day == 2, "Midnight transition increments day to 2")
	_assert(_tm.is_daytime() == false, "00:10 is not daytime")
	_assert(_tm.get_day_period() == "night", "00:10 is 'night'")

	# Reset time
	_tm.set_time(8, 0, 1)

func _test_career_manager() -> void:
	print("\n[Suite 5: CareerManager & Downtown Jobs]")
	var jobs: Array[Dictionary] = _cm.get_available_jobs()
	_assert(jobs.size() >= 5, "At least 5 downtown jobs available")

	var job_ids: Array = []
	for j in jobs:
		job_ids.append(j.get("id", ""))
	_assert(job_ids.has("delivery_worker"), "Delivery Worker job available")
	_assert(job_ids.has("street_vendor"), "Street Vendor job available")
	_assert(job_ids.has("tea_shop_worker"), "Tea Shop Worker job available")
	_assert(job_ids.has("taxi_driver"), "Taxi Driver job available")
	_assert(job_ids.has("shopkeeper"), "Shopkeeper job available")

	_cm.quit_job()
	_assert(_cm.current_job.is_empty(), "Player is initially unemployed")

	var accepted: bool = _cm.accept_job("delivery_worker")
	_assert(accepted == true, "Successfully accepted delivery_worker job")
	_assert(_cm.current_job.get("id") == "delivery_worker", "Current job set to delivery_worker")

	var started: bool = _cm.start_work()
	_assert(started == true, "Started work shift")
	_assert(_cm.is_working == true, "is_working flag set to true")
	_assert(_cm.work_time_remaining == 480.0, "Work shift is 480 game minutes (8 hours)")

	var prev_money: int = _em.get_balance()
	_cm.advance_work(480.0)
	_assert(_cm.is_working == false, "Shift completed after 480 minutes")
	_assert(_em.get_balance() > prev_money, "Player paid shift wage into wallet")

func _test_interaction_system() -> void:
	print("\n[Suite 6: Interaction System & Handlers]")
	var zone := InteractableZoneScript.new()
	zone.prompt_text = "Talk to Mohinga Vendor"
	zone.interaction_type = "food_stall"
	root.add_child(zone)

	_im.register_interactable(zone, zone.prompt_text)
	_assert(_im.current_interactable == zone, "InteractionManager registered zone as current")
	_assert(_im.interaction_prompt == "Talk to Mohinga Vendor", "Prompt text matches")

	# Test FoodStallHandler
	_em.set_balance(10000)
	_nm.hunger = 30.0
	var food_handler: Node = FoodStallHandlerScript.new()
	zone.add_child(food_handler)

	var signal_received := [false]
	zone.interacted.connect(func(): signal_received[0] = true)
	zone.interact()

	_assert(signal_received[0] == true, "InteractableZone emitted interacted signal")
	_assert(_em.get_balance() == 7000, "FoodStall deducted 3,000 MMK (10,000 -> 7,000)")
	_assert(is_equal_approx(_nm.hunger, 70.0), "FoodStall restored 40 hunger (30 -> 70)")

	# Test TeaShopHandler
	var tea_handler: Node = TeaShopHandlerScript.new()
	var tea_zone := InteractableZoneScript.new()
	tea_zone.prompt_text = "Drink Laphet Yay"
	root.add_child(tea_zone)
	tea_zone.add_child(tea_handler)
	_nm.stress = 30.0
	tea_zone.interact()
	_assert(_em.get_balance() == 5500, "TeaShop deducted 1,500 MMK (7,000 -> 5,500)")
	_assert(is_equal_approx(_nm.stress, 20.0), "TeaShop reduced 10 stress")

	# Test ParkBenchHandler
	var bench_handler: Node = ParkBenchHandlerScript.new()
	var bench_zone := InteractableZoneScript.new()
	root.add_child(bench_zone)
	bench_zone.add_child(bench_handler)
	bench_zone.interact()
	_assert(is_equal_approx(_nm.stress, 0.0), "ParkBench reduced stress freely (20 -> 0)")

	_im.unregister_interactable(zone)
	_im.clear_interactable()
	_assert(_im.current_interactable == null, "InteractionManager cleared current interactable")

	zone.queue_free()
	tea_zone.queue_free()
	bench_zone.queue_free()

func _test_player_character() -> void:
	print("\n[Suite 7: Player Rig & ThirdPersonController]")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	_assert(player_scene != null, "scenes/player/player.tscn loaded successfully")
	var player := player_scene.instantiate() as CharacterBody3D
	_assert(player != null, "player.tscn instantiated as CharacterBody3D")
	_assert(player.is_in_group("player"), "Player node registered in 'player' group")
	_assert(player.collision_layer == 2, "Player collision_layer = 2 (Characters)")
	_assert(player.collision_mask == 13, "Player collision_mask = 13 (World|Vehicles|Interactables)")

	var col_shape: CollisionShape3D = player.get_node_or_null("CollisionShape3D")
	_assert(col_shape != null and col_shape.shape is CapsuleShape3D, "Player has CapsuleShape3D collision")

	var mesh_inst: MeshInstance3D = player.get_node_or_null("PlayerMesh")
	_assert(mesh_inst != null and mesh_inst.mesh is CapsuleMesh, "Player has CapsuleMesh visual mesh")

	var cam_yaw: Node3D = player.get_node_or_null("CameraYaw")
	var spring_arm: SpringArm3D = player.get_node_or_null("CameraYaw/SpringArm3D")
	var cam: Camera3D = player.get_node_or_null("CameraYaw/SpringArm3D/Camera3D")
	_assert(cam_yaw != null, "Player has CameraYaw pivot node at head height")
	_assert(spring_arm != null and is_equal_approx(spring_arm.spring_length, 4.0), "SpringArm3D length is 4.0m")
	_assert(cam != null and cam.current == true, "Camera3D configured with current=true")

	# Save/load transforms
	_assert(player.has_method("get_save_data"), "Player has get_save_data method")
	_assert(player.has_method("load_save_data"), "Player has load_save_data method")
	player.call("load_save_data", {"position": [15.0, 1.0, -20.0], "rotation_y": 3.14})
	var pdata: Dictionary = player.call("get_save_data")
	var pos: Array = pdata.get("position", [])
	_assert(is_equal_approx(pos[0], 15.0) and is_equal_approx(pos[2], -20.0), "Player position saved/loaded correctly")

	player.free()

func _test_downtown_world() -> void:
	print("\n[Suite 8: Downtown Yangon Map Scene]")
	var world_scene: PackedScene = load("res://scenes/world/downtown_yangon.tscn")
	_assert(world_scene != null, "scenes/world/downtown_yangon.tscn loaded successfully")
	var world := world_scene.instantiate() as Node3D
	_assert(world != null, "downtown_yangon.tscn instantiated as Node3D")

	_assert(world.has_node("DirectionalLight3D"), "World has DirectionalLight3D sun")
	_assert(world.has_node("WorldEnvironment"), "World has WorldEnvironment sky")
	_assert(world.has_node("Ground"), "World has Ground StaticBody3D")
	_assert(world.has_node("Roads"), "World has Roads network node")
	_assert(world.has_node("Buildings"), "World has Buildings container")
	_assert(world.has_node("Interactables"), "World has Interactables container")
	_assert(world.has_node("Park"), "World has Maha Bandula style Park")
	_assert(world.has_node("SpawnPoint"), "World has SpawnPoint node at (0, 1, 0)")

	var buildings_node: Node = world.get_node("Buildings")
	_assert(buildings_node.get_child_count() >= 8, "World contains at least 8 colonial & urban buildings")

	var interactables_node: Node = world.get_node("Interactables")
	_assert(interactables_node.has_node("FoodStall"), "FoodStall interactable present")
	_assert(interactables_node.has_node("TeaShop"), "TeaShop interactable present")
	_assert(interactables_node.has_node("JobBoard"), "JobBoard interactable present")

	world.free()

func _test_hud_ui() -> void:
	print("\n[Suite 9: HUD Interface]")
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	_assert(hud_scene != null, "scenes/ui/hud.tscn loaded successfully")
	var hud := hud_scene.instantiate() as CanvasLayer
	root.add_child(hud)

	var money_lbl := hud.get_node_or_null("%MoneyLabel") as Label
	var time_lbl := hud.get_node_or_null("%TimeLabel") as Label
	var day_lbl := hud.get_node_or_null("%DayLabel") as Label
	var hunger_bar := hud.get_node_or_null("%HungerBar") as ProgressBar
	var energy_bar := hud.get_node_or_null("%EnergyBar") as ProgressBar
	var prompt_lbl := hud.get_node_or_null("%InteractionPrompt") as Label

	_assert(money_lbl != null, "HUD has %MoneyLabel")
	_assert(time_lbl != null, "HUD has %TimeLabel")
	_assert(day_lbl != null, "HUD has %DayLabel")
	_assert(hunger_bar != null, "HUD has %HungerBar")
	_assert(energy_bar != null, "HUD has %EnergyBar")
	_assert(prompt_lbl != null, "HUD has %InteractionPrompt")

	_em.set_balance(65000)
	_assert(money_lbl.text == "K 65,000", "HUD updates money format with comma separator: 'K 65,000'")

	_nm.need_changed.emit("hunger", 55.0)
	_assert(is_equal_approx(hunger_bar.value, 55.0), "HUD HungerBar reflects updated need")

	_im.interactable_entered.emit(null, "Order Shan Noodles")
	_assert(prompt_lbl.visible == true, "HUD InteractionPrompt becomes visible when in range")
	_assert(prompt_lbl.text == "[E] Order Shan Noodles", "Prompt text shows '[E] Order Shan Noodles'")

	_im.interactable_exited.emit()
	_assert(prompt_lbl.visible == false, "HUD InteractionPrompt hides when out of range")

	hud.queue_free()

func _test_main_game_scene() -> void:
	print("\n[Suite 10: MainGame Top-Level Scene Composition]")
	var main_scene: PackedScene = load("res://scenes/main/main_game.tscn")
	_assert(main_scene != null, "scenes/main/main_game.tscn loaded successfully")
	var main_game := main_scene.instantiate() as Node3D
	_assert(main_game != null, "main_game.tscn instantiated cleanly")
	_assert(main_game.has_node("DowntownYangon"), "MainGame includes DowntownYangon instance")
	_assert(main_game.has_node("Player"), "MainGame includes Player instance")
	_assert(main_game.has_node("HUD"), "MainGame includes HUD instance")
	main_game.free()

func _test_save_load_system() -> void:
	print("\n[Suite 11: SaveManager Serialization & Persistence]")
	_em.set_balance(52500)
	_nm.hunger = 75.0
	_nm.energy = 85.0
	_tm.set_time(14, 30, 3)
	_skm.add_xp("driving", 250.0)
	_inm.clear_inventory()
	_inm.add_item("mohinga", 4)
	_hsm.current_housing_tier = "tier_2_shophouse"

	var saved: bool = _sm.save_game()
	_assert(saved == true, "save_game executed successfully")
	_assert(_sm.has_save() == true, "has_save reports true")

	# Modify in-memory state
	_em.set_balance(1000)
	_nm.hunger = 20.0
	_tm.set_time(6, 0, 1)
	_skm.reset_skills()
	_inm.clear_inventory()
	_hsm.current_housing_tier = "tier_0_bench"

	var loaded: bool = _sm.load_game()
	_assert(loaded == true, "load_game executed successfully")
	_assert(_em.get_balance() == 52500, "Restored wallet balance to 52,500 MMK")
	_assert(is_equal_approx(_nm.hunger, 75.0), "Restored hunger level to 75.0")
	_assert(_tm.game_hour == 14 and _tm.game_minute == 30, "Restored time to 14:30")
	_assert(_tm.game_day == 3, "Restored day to 3")
	_assert(_skm.get_level("driving") >= 2, "Restored driving skill level from save")
	_assert(_inm.get_item_count("mohinga") == 4, "Restored inventory Mohinga count from save")
	_assert(_hsm.current_housing_tier == "tier_2_shophouse", "Restored housing tier from save")

	_sm.delete_save()
	_assert(_sm.has_save() == false, "Save file cleaned up after test")

func _test_skill_manager() -> void:
	print("\n[Suite 12: SkillManager & Progression System]")
	_skm.reset_skills()
	_assert(_skm.get_level("driving") == 1, "Initial driving level is 1")
	_assert(_skm.get_level("cooking") == 1, "Initial cooking level is 1")
	_assert(_skm.get_level("customer_service") == 1, "Initial customer_service level is 1")
	_assert(_skm.get_level("business") == 1, "Initial business level is 1")
	_assert(_skm.get_level("mechanic") == 1, "Initial mechanic level is 1")
	_assert(is_equal_approx(_skm.get_xp("driving"), 0.0), "Initial driving XP is 0.0")

	# Test XP threshold: level 1 requires 100.0 * 1 = 100.0 XP
	_assert(is_equal_approx(_skm.get_xp_for_next_level("driving"), 100.0), "XP needed for level 2 is 100.0")
	var xp_signal_fired: Array[bool] = [false]
	var level_signal_fired: Array[bool] = [false]
	var gained_amount: Array[float] = [0.0]
	var new_lvl_val: Array[int] = [0]

	var xp_callable: Callable = func(s_name: String, amt: float, _cur_xp: float) -> void:
		if s_name == "driving":
			xp_signal_fired[0] = true
			gained_amount[0] = amt
	var lvl_callable: Callable = func(s_name: String, new_lvl: int) -> void:
		if s_name == "driving":
			level_signal_fired[0] = true
			new_lvl_val[0] = new_lvl

	_skm.skill_xp_gained.connect(xp_callable)
	_skm.skill_leveled_up.connect(lvl_callable)

	_skm.add_xp("driving", 60.0)
	_assert(xp_signal_fired[0] == true and is_equal_approx(gained_amount[0], 60.0), "skill_xp_gained emitted with 60.0 XP")
	_assert(is_equal_approx(_skm.get_xp("driving"), 60.0), "Current driving XP is 60.0")
	_assert(_skm.get_level("driving") == 1, "Still at level 1 with 60 XP")
	_assert(level_signal_fired[0] == false, "skill_leveled_up not emitted before threshold")

	# Add 60 more XP -> total 120 XP -> crosses 100 threshold -> level 2, 20 XP remainder
	_skm.add_xp("driving", 60.0)
	_assert(_skm.get_level("driving") == 2, "Driving reached level 2")
	_assert(is_equal_approx(_skm.get_xp("driving"), 20.0), "Driving XP remainder is 20.0")
	_assert(level_signal_fired[0] == true and new_lvl_val[0] == 2, "skill_leveled_up emitted with level 2")

	# Level 2 threshold is 100.0 * 2 = 200.0
	_assert(is_equal_approx(_skm.get_xp_for_next_level("driving"), 200.0), "XP needed for level 3 is 200.0")

	_skm.skill_xp_gained.disconnect(xp_callable)
	_skm.skill_leveled_up.disconnect(lvl_callable)

	# Multi-level leap to max level 5
	_skm.add_xp("driving", 1000.0)
	_assert(_skm.get_level("driving") == 5, "Driving maxed out at level 5")
	_assert(_skm.has_skill_level("driving", 5) == true, "has_skill_level(driving, 5) returns true")
	_assert(_skm.has_skill_level("driving", 6) == false, "has_skill_level(driving, 6) returns false")

	# Test skill bonuses
	_assert(_skm.get_driving_fuel_multiplier() < 1.0, "Driving level 5 reduces fuel multiplier")
	_skm.add_xp("cooking", 150.0)
	_assert(_skm.get_cooking_margin_bonus() > 0.0, "Cooking level 2 gives positive margin bonus")
	_skm.add_xp("customer_service", 150.0)
	_assert(_skm.get_customer_service_tip_bonus() > 0.0, "Customer service level 2 gives positive tip bonus")
	_skm.add_xp("business", 150.0)
	_assert(_skm.get_business_discount_multiplier() < 1.0, "Business level 2 reduces lease multiplier")
	_skm.add_xp("mechanic", 150.0)
	_assert(_skm.get_mechanic_discount_multiplier() < 1.0, "Mechanic level 2 reduces maintenance multiplier")

	# Test save and load data
	var skill_save: Dictionary = _skm.get_save_data()
	_assert(skill_save.has("skills"), "SkillManager export contains 'skills' key")
	_skm.reset_skills()
	_assert(_skm.get_level("driving") == 1, "driving reset to 1")
	_skm.load_save_data(skill_save)
	_assert(_skm.get_level("driving") == 5, "driving restored to level 5 via load_save_data")

func _test_inventory_manager() -> void:
	print("\n[Suite 13: InventoryManager & Consumables System]")
	_inm.clear_inventory()
	_assert(_inm.slots.size() == 0, "Inventory initially empty")
	_assert(_inm.is_full() == false, "Inventory is not full initially")

	# Test item catalog definitions
	var mohinga_def: Dictionary = _inm.get_item_definition("mohinga")
	_assert(mohinga_def.get("name") == "Mohinga", "Mohinga definition found in catalog")
	_assert(mohinga_def.get("category") == "food", "Mohinga category is food")
	_assert(is_equal_approx(float(mohinga_def.get("hunger_restore")), 40.0), "Mohinga restores 40.0 hunger")
	_assert(int(mohinga_def.get("value")) == 2500, "Mohinga value is 2,500 MMK")

	var tea_def: Dictionary = _inm.get_item_definition("laphet_yay")
	_assert(tea_def.get("name") == "Laphet Yay", "Laphet Yay definition found")
	_assert(is_equal_approx(float(tea_def.get("stress_reduce")), 10.0), "Laphet Yay reduces 10.0 stress")

	# Test add_item & stacking
	var added1: bool = _inm.add_item("mohinga", 2)
	_assert(added1 == true, "Added 2 Mohinga to inventory")
	_assert(_inm.get_item_count("mohinga") == 2, "get_item_count('mohinga') returns 2")
	_assert(_inm.slots.size() == 1, "1 slot occupied")

	var added2: bool = _inm.add_item("mohinga", 3)
	_assert(added2 == true, "Added 3 more Mohinga")
	_assert(_inm.get_item_count("mohinga") == 5, "Total Mohinga stacked to 5 in single slot")
	_assert(_inm.slots.size() == 1, "Still 1 slot occupied due to stacking")

	_inm.add_item("laphet_yay", 1)
	_inm.add_item("energy_drink", 1)
	_assert(_inm.slots.size() == 3, "3 slots occupied with distinct items")

	# Test remove_item
	var removed_partial: bool = _inm.remove_item("mohinga", 2)
	_assert(removed_partial == true, "Removed 2 Mohinga")
	_assert(_inm.get_item_count("mohinga") == 3, "Remaining Mohinga is 3")

	var removed_over: bool = _inm.remove_item("mohinga", 10)
	_assert(removed_over == false, "Cannot remove 10 Mohinga when only 3 available")

	# Test slot capacity cap (16 slots)
	_inm.clear_inventory()
	for i in range(16):
		var dummy_id: String = "test_item_%d" % i
		_inm.slots.append({"id": dummy_id, "quantity": 1})
	_assert(_inm.is_full() == true, "Inventory recognizes full state at 16 slots")
	var reject_add: bool = _inm.add_item("shan_noodles", 1)
	_assert(reject_add == false, "add_item rejected when 16 slots are full")

	# Test use_item with NeedsManager integration
	_inm.clear_inventory()
	_inm.add_item("mohinga", 2)
	_nm.hunger = 40.0
	var used_food: bool = _inm.use_item("mohinga")
	_assert(used_food == true, "use_item('mohinga') succeeded")
	_assert(is_equal_approx(_nm.hunger, 80.0), "NeedsManager hunger restored from 40 to 80")
	_assert(_inm.get_item_count("mohinga") == 1, "Mohinga count reduced to 1 after consumption")

	_inm.add_item("laphet_yay", 1)
	_nm.stress = 50.0
	_inm.use_item("laphet_yay")
	_assert(is_equal_approx(_nm.stress, 40.0), "NeedsManager stress reduced by Laphet Yay (50 -> 40)")

	_inm.add_item("energy_drink", 1)
	_nm.energy = 50.0
	_inm.use_item("energy_drink")
	_assert(is_equal_approx(_nm.energy, 85.0), "NeedsManager energy restored by Sparks Energy Drink (50 -> 85)")

	# Test save and load data
	_inm.clear_inventory()
	_inm.add_item("shan_noodles", 3)
	_inm.add_item("transit_pass", 1)
	var inv_save: Dictionary = _inm.get_save_data()
	_inm.clear_inventory()
	_assert(_inm.get_item_count("shan_noodles") == 0, "Inventory cleared")
	_inm.load_save_data(inv_save)
	_assert(_inm.get_item_count("shan_noodles") == 3, "Restored 3 Shan Noodles from save")
	_assert(_inm.has_item("transit_pass", 1) == true, "Restored YBS transit pass from save")

func _test_housing_manager() -> void:
	print("\n[Suite 14: HousingManager & Rest Systems]")
	_hsm.current_housing_tier = "tier_0_bench"
	_assert(_hsm.current_housing_tier == "tier_0_bench", "Default housing tier is tier_0_bench")

	var all_tiers: Dictionary = _hsm.get_all_tiers()
	_assert(all_tiers.size() >= 5, "At least 5 housing tiers defined")
	_assert(all_tiers.has("tier_0_bench"), "tier_0_bench defined")
	_assert(all_tiers.has("tier_1_hostel"), "tier_1_hostel defined")
	_assert(all_tiers.has("tier_2_shophouse"), "tier_2_shophouse defined")
	_assert(all_tiers.has("tier_3_apartment"), "tier_3_apartment defined")
	_assert(all_tiers.has("tier_4_heritage"), "tier_4_heritage defined")

	# Test rent_property with EconomyManager
	_em.set_balance(10000)
	var rented_hostel: bool = _hsm.rent_property("tier_1_hostel")
	_assert(rented_hostel == true, "Successfully rented Mahabandula Hostel Bunk for 5,000 MMK")
	_assert(_em.get_balance() == 5000, "Economy balance deducted to 5,000 MMK")
	_assert(_hsm.current_housing_tier == "tier_1_hostel", "Current housing tier updated to tier_1_hostel")

	# Cannot afford expensive downtown shophouse (150,000 MMK)
	var rented_shophouse: bool = _hsm.rent_property("tier_2_shophouse")
	_assert(rented_shophouse == false, "Cannot rent tier_2_shophouse when balance is 5,000 MMK")
	_assert(_hsm.current_housing_tier == "tier_1_hostel", "Housing tier unchanged after failed rent")

	# Test pay_rent
	_em.set_balance(6000)
	var paid: bool = _hsm.pay_rent()
	_assert(paid == true, "Successfully paid daily hostel rent (5,000 MMK)")
	_assert(_em.get_balance() == 1000, "Balance deducted to 1,000 MMK")

	# Test eviction safety net on rent default
	_em.set_balance(500) # cannot pay 5000 rent
	var evicted_res: bool = _hsm.pay_rent()
	_assert(evicted_res == false, "pay_rent returned false on default")
	_assert(_hsm.current_housing_tier == "tier_0_bench", "Eviction safety net placed player safely at tier_0_bench")

	# Test sleep_at_home with tier_0_bench (low energy recovery, hygiene decay)
	_tm.set_time(22, 0, 1)
	_nm.energy = 20.0
	_nm.hygiene = 70.0
	_hsm.sleep_at_home(8)
	_assert(_tm.game_hour == 6 and _tm.game_day == 2, "TimeManager advanced 8 hours (22:00 -> 06:00, day 2)")
	_assert(is_equal_approx(_nm.energy, 60.0), "Bench sleep restored 40 energy (rate 0.5)")
	_assert(_nm.hygiene < 70.0, "Bench sleep degraded hygiene due to street exposure")

	# Test sleep_at_home with higher tier (e.g. tier_1_hostel has hygiene recovery = 30)
	_em.set_balance(10000)
	_hsm.rent_property("tier_1_hostel")
	_nm.energy = 20.0
	_nm.hygiene = 40.0
	_hsm.sleep_at_home(8)
	_assert(is_equal_approx(_nm.energy, 100.0), "Hostel sleep restored full 80 energy (rate 1.0)")
	_assert(is_equal_approx(_nm.hygiene, 70.0), "Hostel sleep restored +30 hygiene from washroom (40 -> 70)")

	# Test save and load data
	var house_save: Dictionary = _hsm.get_save_data()
	_hsm.current_housing_tier = "tier_0_bench"
	_hsm.load_save_data(house_save)
	_assert(_hsm.current_housing_tier == "tier_1_hostel", "Restored housing tier tier_1_hostel from save")

func _test_delivery_runner() -> void:
	print("\n[Suite 15: DeliveryRunner Career Loop]")
	var runner := DeliveryRunnerScript.new()
	root.add_child(runner)

	var order: Dictionary = runner.create_order("Pansodan Depot", "Merchant St #12", 60.0, 8000)
	_assert(order.get("base_pay") == 8000, "Delivery order created with 8,000 MMK base pay")
	_assert(order.get("depot") == "Pansodan Depot", "Depot matches")

	var accepted: bool = runner.accept_order(order)
	_assert(accepted == true, "Delivery order accepted")
	_assert(runner.current_state == DeliveryRunner.OrderState.ASSIGNED, "Current state is ASSIGNED")

	var picked_up: bool = runner.pickup_package()
	_assert(picked_up == true, "Package picked up from depot")
	_assert(runner.current_state == DeliveryRunner.OrderState.PICKED_UP, "Current state is PICKED_UP")
	_assert(_inm.has_item("delivery_parcel", 1) == true, "Parcel added to inventory during transit")

	runner.advance_timer(10.0) # 50 minutes remaining
	_assert(is_equal_approx(float(runner.active_order.get("time_remaining")), 50.0), "10 minutes deducted from delivery timer")

	var initial_balance: int = _em.get_balance()
	var prev_driving_xp: float = _skm.get_xp("driving")
	var delivered: bool = runner.deliver_package()
	_assert(delivered == true, "Package successfully delivered to destination")
	_assert(_em.get_balance() >= initial_balance + 8000, "Economy credited 8,000 MMK base pay + tip")
	_assert(_skm.get_xp("driving") > prev_driving_xp, "Driving XP awarded upon delivery")
	_assert(_inm.has_item("delivery_parcel", 1) == false, "Parcel removed from inventory upon delivery")
	_assert(runner.current_state == DeliveryRunner.OrderState.IDLE, "Runner state returned to IDLE")

	runner.queue_free()

func _test_street_vendor_runner() -> void:
	print("\n[Suite 16: StreetVendorRunner Career Loop]")
	var vendor := StreetVendorRunnerScript.new()
	root.add_child(vendor)

	var opened: bool = vendor.open_stall()
	_assert(opened == true, "Street vendor stall opened")
	_assert(vendor.is_stall_open == true, "is_stall_open is true")

	var order: Dictionary = vendor.spawn_order("mohinga")
	_assert(not order.is_empty(), "Spawned Mohinga customer order")
	_assert(order.get("dish_id") == "mohinga", "Order dish_id is mohinga")
	_assert(vendor.active_orders.size() == 1, "Active orders count is 1")

	var prepped: bool = vendor.prepare_order(0)
	_assert(prepped == true, "Prepared Mohinga order")
	_assert(vendor.active_orders[0].get("is_prepared") == true, "Order marked as prepared")

	var prev_balance: int = _em.get_balance()
	var prev_cooking_xp: float = _skm.get_xp("cooking")
	var earned: int = vendor.serve_order(0)
	_assert(earned >= 5000 and earned <= 12000, "Earned within 5,000 - 12,000 MMK range (Earned: %d MMK)" % earned)
	_assert(_em.get_balance() == prev_balance + earned, "Economy credited food stall earnings")
	_assert(_skm.get_xp("cooking") > prev_cooking_xp, "Cooking XP awarded for serving dish")
	_assert(vendor.active_orders.size() == 0, "Served order removed from active list")

	vendor.close_stall()
	_assert(vendor.is_stall_open == false, "Stall successfully closed")

	vendor.queue_free()

func _test_taxi_shift_runner() -> void:
	print("\n[Suite 17: TaxiShiftRunner Career Loop]")
	var taxi := TaxiShiftRunnerScript.new()
	root.add_child(taxi)

	var started: bool = taxi.start_shift()
	_assert(started == true, "Taxi shift started")
	_assert(taxi.current_state == TaxiShiftRunner.TaxiState.CRUISING, "Current state is CRUISING")

	var hail: Dictionary = taxi.generate_hail("Daw San", "Sule Pagoda", "Junction City", 4.0)
	_assert(hail.get("passenger_name") == "Daw San", "Hail generated for Daw San")
	_assert(is_equal_approx(float(hail.get("distance_km")), 4.0), "Distance is 4.0 km")

	var accepted: bool = taxi.accept_hail(hail)
	_assert(accepted == true, "Passenger hail accepted")

	var boarded: bool = taxi.board_passenger()
	_assert(boarded == true, "Passenger boarded vehicle")
	_assert(taxi.current_state == TaxiShiftRunner.TaxiState.PASSENGER_ONBOARD, "State is PASSENGER_ONBOARD")

	var prev_balance: int = _em.get_balance()
	var prev_driving_xp: float = _skm.get_xp("driving")
	var net_earned: int = taxi.complete_trip(1.0)
	_assert(net_earned > 0, "Net taxi earnings positive (Earned: %d MMK)" % net_earned)
	_assert(_em.get_balance() == prev_balance + net_earned, "Net fare credited to EconomyManager")
	_assert(_skm.get_xp("driving") > prev_driving_xp, "Driving XP awarded for taxi trip")
	_assert(taxi.trips_completed == 1, "Trips completed count incremented to 1")

	taxi.end_shift()
	_assert(taxi.current_state == TaxiShiftRunner.TaxiState.OFF_DUTY, "Shift ended, state is OFF_DUTY")

	taxi.queue_free()

func _test_m4_living_city_systems() -> void:
	print("\n[Suite 18: Milestone M4 — Living City NPCs, Traffic & Weather]")
	# 1. NPC Pedestrian Script
	var npc := NPCPedestrianScript.new()
	root.add_child(npc)
	_assert(npc.npc_name == "U Kyaw", "Pedestrian default name is U Kyaw")
	_assert(npc.archetype == "office_worker", "Pedestrian default archetype is office_worker")
	_assert(is_equal_approx(npc.walk_speed, 2.0), "Pedestrian default walk_speed is 2.0 m/s")

	# Contextual greetings
	npc.archetype = "monk"
	var monk_talk: String = npc.talk_to_player()
	_assert(monk_talk.contains("Mingalarba"), "Monk greeting contains Burmese greeting Mingalarba")

	npc.archetype = "street_vendor"
	var vendor_talk: String = npc.talk_to_player()
	_assert(vendor_talk.contains("Mohinga"), "Vendor greeting offers authentic Mohinga")

	# Distance LOD transitions
	npc.global_position = Vector3.ZERO
	npc.update_lod(Vector3(10, 0, 0)) # < 25m
	_assert(npc.current_lod == NPCPedestrianScript.LOD_FULL and npc.visible == true, "LOD < 25m is LOD_FULL and visible")
	_assert(npc.collision_layer == 2, "LOD_FULL collision_layer = 2 (Characters)")

	npc.update_lod(Vector3(40, 0, 0)) # 25m - 60m
	_assert(npc.current_lod == NPCPedestrianScript.LOD_SIMPLIFIED and npc.visible == true, "LOD 25-60m is LOD_SIMPLIFIED and visible")
	_assert(npc.collision_layer == 0, "LOD_SIMPLIFIED has collision disabled")

	npc.update_lod(Vector3(100, 0, 0)) # > 60m
	_assert(npc.current_lod == NPCPedestrianScript.LOD_OFFSCREEN and npc.visible == false, "LOD > 60m is LOD_OFFSCREEN and hidden")

	# Schedule Evaluation
	npc.schedule_stops = [Vector3(0, 0, 0), Vector3(10, 0, 0)]
	npc.evaluate_schedule(14)
	_assert(npc.current_stop_index == 1, "Schedule evaluation maps game hour 14 to stop 1")
	npc.queue_free()

	# 2. NPC Pedestrian Scene
	var npc_scene: PackedScene = load("res://scenes/npcs/npc_pedestrian.tscn")
	_assert(npc_scene != null, "scenes/npcs/npc_pedestrian.tscn loaded successfully")
	var npc_inst: CharacterBody3D = npc_scene.instantiate() as CharacterBody3D
	root.add_child(npc_inst)
	_assert(npc_inst.collision_layer == 2, "Pedestrian scene collision_layer is 2 (Characters)")
	_assert(npc_inst.has_node("CollisionShape3D"), "Pedestrian scene has CollisionShape3D")
	_assert(npc_inst.has_node("MeshInstance3D"), "Pedestrian scene has MeshInstance3D")
	_assert(npc_inst.has_node("TalkArea/InteractableZone"), "Pedestrian scene has TalkArea with child InteractableZone")
	npc_inst.queue_free()

	# 3. TrafficCar Script
	var car := TrafficCarScript.new()
	root.add_child(car)
	_assert(is_equal_approx(car.travel_speed, 8.0), "Traffic car travel_speed is 8.0 m/s")
	_assert(car.car_type == "ybs_bus", "Traffic car default type is 'ybs_bus'")
	_assert(car.collision_layer == 4, "Traffic car collision_layer is 4 (Layer 3 Vehicles)")
	_assert(car.collision_mask == 7, "Traffic car collision_mask is 7 (World|Characters|Vehicles)")

	car.set_waypoints([Vector3(0, 0, 0), Vector3(0, 0, 20)])
	_assert(car.waypoints.size() == 2, "set_waypoints populated 2 road waypoints")
	car.set_tire_traction(0.8)
	_assert(is_equal_approx(car.tire_traction, 0.8), "set_tire_traction updated tire traction to 0.8")
	car.advance_traffic(0.1)
	_assert(car.current_speed > 0.0, "Car advanced forward when road is clear")
	car.queue_free()

	# 4. TrafficCar Scene
	var car_scene: PackedScene = load("res://scenes/vehicles/traffic_car.tscn")
	_assert(car_scene != null, "scenes/vehicles/traffic_car.tscn loaded successfully")
	var car_inst: CharacterBody3D = car_scene.instantiate() as CharacterBody3D
	root.add_child(car_inst)
	_assert(car_inst.collision_layer == 4, "TrafficCar scene collision_layer is 4 (Vehicles)")
	_assert(car_inst.has_node("CollisionShape3D"), "TrafficCar scene has CollisionShape3D")
	_assert(car_inst.has_node("MeshInstance3D"), "TrafficCar scene has MeshInstance3D")
	_assert(car_inst.has_node("ObstacleRay"), "TrafficCar scene has ObstacleRay")
	var obs_ray: RayCast3D = car_inst.get_node("ObstacleRay") as RayCast3D
	_assert(is_equal_approx(obs_ray.target_position.z, -6.0), "ObstacleRay points 6.0m forward (z = -6.0)")
	car_inst.queue_free()

	# 5. WeatherController Script
	var wc := WeatherControllerScript.new()
	root.add_child(wc)
	wc.update_sun(6, 0)
	_assert(is_equal_approx(wc.get_sun_angle(), 0.0), "06:00 sunrise sun angle is 0.0°")
	_assert(is_equal_approx(wc.get_sun_energy(), 0.4), "06:00 dawn sun energy is 0.4")

	wc.update_sun(12, 0)
	_assert(is_equal_approx(wc.get_sun_angle(), 90.0), "12:00 noon sun angle is 90.0°")
	_assert(is_equal_approx(wc.get_sun_energy(), 1.2), "12:00 noon sun energy is 1.2")

	wc.update_sun(18, 0)
	_assert(is_equal_approx(wc.get_sun_angle(), 180.0), "18:00 sunset sun angle is 180.0°")

	wc.set_weather(WeatherControllerScript.CLEAR)
	_assert(wc.get_weather() == WeatherControllerScript.CLEAR, "WeatherController sets CLEAR weather")
	_assert(is_equal_approx(wc.get_vehicle_traction(), 1.0), "CLEAR weather traction is 1.0")

	wc.set_weather(WeatherControllerScript.RAIN)
	_assert(wc.get_weather() == WeatherControllerScript.RAIN, "WeatherController sets RAIN weather")
	_assert(wc.get_vehicle_traction() < 1.0, "RAIN weather reduces vehicle traction (< 1.0)")
	_assert(_nm.stress_growth > 1.5, "RAIN weather elevates player stress growth")

	wc.set_weather(WeatherControllerScript.MONSOON)
	_assert(wc.get_weather() == WeatherControllerScript.MONSOON, "WeatherController sets MONSOON weather")
	_assert(wc.get_vehicle_traction() <= 0.55, "MONSOON weather reduces vehicle traction to <= 0.55")

	wc.set_weather(WeatherControllerScript.CLEAR)
	wc.queue_free()

	# 6. WeatherEnvironment Scene
	var env_scene: PackedScene = load("res://scenes/world/weather_environment.tscn")
	_assert(env_scene != null, "scenes/world/weather_environment.tscn loaded successfully")
	var env_inst: Node3D = env_scene.instantiate() as Node3D
	root.add_child(env_inst)
	_assert(env_inst.has_node("SunLight"), "WeatherEnvironment has SunLight")
	_assert(env_inst.has_node("RainParticles"), "WeatherEnvironment has RainParticles")
	var sun_light: DirectionalLight3D = env_inst.get_node("SunLight") as DirectionalLight3D
	_assert(sun_light.shadow_enabled == true, "SunLight has shadows enabled")
	var rain_part: CPUParticles3D = env_inst.get_node("RainParticles") as CPUParticles3D
	_assert(rain_part.amount >= 300, "RainParticles amount >= 300")
	_assert(rain_part.emission_shape == CPUParticles3D.EMISSION_SHAPE_BOX, "RainParticles emission_shape is Box")

	var env_wc := env_inst as WeatherController
	_assert(env_wc != null, "WeatherEnvironment root script is WeatherController")
	env_wc.set_weather(WeatherControllerScript.RAIN)
	_assert(rain_part.emitting == true, "RainParticles emit in RAIN weather")
	env_wc.set_weather(WeatherControllerScript.CLEAR)
	_assert(rain_part.emitting == false, "RainParticles stop emitting in CLEAR weather")
	env_inst.queue_free()

func _test_m5_ui_suite() -> void:
	var m5_suite := TestM5UISuiteScript.new()
	root.add_child(m5_suite)
	m5_suite.run_all()
	tests_passed += m5_suite.tests_passed
	tests_failed += m5_suite.tests_failed
	m5_suite.queue_free()

func _test_m7_polish_suite() -> void:
	var m7_suite := TestM7PolishSuiteScript.new()
	root.add_child(m7_suite)
	m7_suite.run_all()
	tests_passed += m7_suite.tests_passed
	tests_failed += m7_suite.tests_failed
	m7_suite.queue_free()

func _test_ball_and_city() -> void:
	var ball_suite := TestBallAndCityScript.new()
	root.add_child(ball_suite)
	ball_suite.run_all()
	tests_passed += ball_suite.tests_passed
	tests_failed += ball_suite.tests_failed
	ball_suite.queue_free()





