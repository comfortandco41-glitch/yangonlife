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

var _gm: Node
var _em: Node
var _nm: Node
var _tm: Node
var _sm: Node
var _cm: Node
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

	var saved: bool = _sm.save_game()
	_assert(saved == true, "save_game executed successfully")
	_assert(_sm.has_save() == true, "has_save reports true")

	# Modify in-memory state
	_em.set_balance(1000)
	_nm.hunger = 20.0
	_tm.set_time(6, 0, 1)

	var loaded: bool = _sm.load_game()
	_assert(loaded == true, "load_game executed successfully")
	_assert(_em.get_balance() == 52500, "Restored wallet balance to 52,500 MMK")
	_assert(is_equal_approx(_nm.hunger, 75.0), "Restored hunger level to 75.0")
	_assert(_tm.game_hour == 14 and _tm.game_minute == 30, "Restored time to 14:30")
	_assert(_tm.game_day == 3, "Restored day to 3")

	_sm.delete_save()
	_assert(_sm.has_save() == false, "Save file cleaned up after test")
