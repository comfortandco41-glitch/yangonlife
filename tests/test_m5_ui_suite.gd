class_name TestM5UISuite
extends Node
## Automated Test Suite for Milestone M5: Full UI Suite, Phone Apps & Web Play Readiness.
##
## Tests PhoneController, InventoryMenuController, StartScreenController, and PauseMenuController.

const PhoneControllerScript = preload("res://scripts/ui/phone_controller.gd")
const InventoryMenuControllerScript = preload("res://scripts/ui/inventory_menu_controller.gd")
const StartScreenControllerScript = preload("res://scripts/ui/start_screen_controller.gd")
const PauseMenuControllerScript = preload("res://scripts/ui/pause_menu_controller.gd")

signal tests_finished(passed: int, failed: int)

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
	print("  [Suite 19: Milestone M5 — Full UI Suite & Phone Apps]")
	print("==================================================")

	test_phone_menu()
	test_inventory_menu()
	test_start_screen()
	test_pause_menu()

	print("\n--------------------------------------------------")
	print("M5 TEST RESULTS: %d PASSED, %d FAILED" % [tests_passed, tests_failed])
	print("--------------------------------------------------")
	tests_finished.emit(tests_passed, tests_failed)

func test_phone_menu() -> void:
	print("\n[M5 Sub-Suite 1: PhoneController & phone_menu.tscn]")
	var phone_scene: PackedScene = load("res://scenes/ui/phone_menu.tscn")
	_assert(phone_scene != null, "scenes/ui/phone_menu.tscn loaded successfully")

	var phone := phone_scene.instantiate() as PhoneController
	_assert(phone != null, "phone_menu.tscn instantiated as PhoneController")
	_assert(phone is Control, "PhoneController extends Control")
	add_child(phone)

	# Initial state
	_assert(phone.visible == false, "Phone is initially hidden")
	_assert(phone.is_open == false, "phone.is_open is false initially")

	# Open phone
	phone.open_phone()
	_assert(phone.visible == true, "open_phone() sets visible = true")
	_assert(phone.is_open == true, "open_phone() sets is_open = true")
	_assert(phone.current_app == "home", "Default active screen is 'home'")

	# 1. Bank App
	phone.show_app("bank")
	_assert(phone.current_app == "bank", "show_app('bank') switched to bank")
	_assert(phone.bank_app.visible == true, "BankApp container is visible")
	_assert(phone.bank_balance_label != null, "Bank app has BankBalanceLabel")
	_assert("MMK" in phone.bank_balance_label.text, "Bank balance displays MMK currency")

	# Test pay rent quick action
	var em := get_node_or_null("/root/EconomyManager")
	if em:
		em.set_balance(20000)
		phone.pay_rent_action()
		_assert(em.get_balance() < 20000, "pay_rent_action deducted funds from EconomyManager")

	# 2. Jobs App
	phone.show_app("jobs")
	_assert(phone.current_app == "jobs", "show_app('jobs') switched to jobs")
	_assert(phone.jobs_app.visible == true, "JobsApp container is visible")
	_assert(phone.job_status_label != null, "Jobs app has JobStatusLabel")
	_assert(phone.jobs_list_container.get_child_count() >= 5, "Jobs app lists at least 5 vacant downtown positions")

	# Test applying for delivery worker
	phone.apply_job_action("delivery_worker")
	var cm := get_node_or_null("/root/CareerManager")
	if cm:
		_assert(cm.current_job.get("id") == "delivery_worker", "apply_job_action successfully accepted delivery_worker")

	# 3. GPS Map App
	phone.show_app("map")
	_assert(phone.current_app == "map", "show_app('map') switched to map")
	_assert(phone.map_app.visible == true, "MapApp container is visible")
	_assert(phone.poi_list_container.get_child_count() == 5, "GPS Map lists 5 Downtown Yangon POIs (Sule, Park, Chinatown, City Hall, Botahtaung)")

	# 4. Status App
	phone.show_app("status")
	_assert(phone.current_app == "status", "show_app('status') switched to status")
	_assert(phone.status_app.visible == true, "StatusApp container is visible")
	_assert(phone.hunger_meter != null, "Status app has HungerMeter")
	_assert(phone.energy_meter != null, "Status app has EnergyMeter")
	_assert(phone.hygiene_meter != null, "Status app has HygieneMeter")
	_assert(phone.stress_meter != null, "Status app has StressMeter")
	_assert(phone.efficiency_label != null, "Status app has EfficiencyLabel")

	# Return to home
	phone.return_to_home()
	_assert(phone.current_app == "home", "return_to_home() returned to 'home' launcher")
	_assert(phone.home_screen.visible == true, "HomeScreen container is visible")

	# Close phone
	phone.close_phone()
	_assert(phone.visible == false, "close_phone() hides phone menu")
	_assert(phone.is_open == false, "close_phone() sets is_open = false")

	phone.queue_free()

func test_inventory_menu() -> void:
	print("\n[M5 Sub-Suite 2: InventoryMenuController & inventory_menu.tscn]")
	var inv_scene: PackedScene = load("res://scenes/ui/inventory_menu.tscn")
	_assert(inv_scene != null, "scenes/ui/inventory_menu.tscn loaded successfully")

	var inv_menu := inv_scene.instantiate() as InventoryMenuController
	_assert(inv_menu != null, "inventory_menu.tscn instantiated as InventoryMenuController")
	_assert(inv_menu is Control, "InventoryMenuController extends Control")
	add_child(inv_menu)

	# Initial state
	_assert(inv_menu.visible == false, "InventoryMenu is initially hidden")
	_assert(inv_menu.is_open == false, "inv_menu.is_open is false initially")

	# Setup inventory items
	var inm := get_node_or_null("/root/InventoryManager")
	if inm:
		inm.clear_inventory()
		inm.add_item("mohinga", 2)
		inm.add_item("laphet_yay", 1)

	# Open inventory
	inv_menu.open_inventory()
	_assert(inv_menu.visible == true, "open_inventory() sets visible = true")
	_assert(inv_menu.is_open == true, "open_inventory() sets is_open = true")
	_assert(inv_menu.slots_grid.get_child_count() == 16, "Inventory grid renders exactly 16 slots (4x4)")

	# Slot selection
	inv_menu.select_slot(0)
	_assert(inv_menu.selected_slot_index == 0, "select_slot(0) sets selected_slot_index = 0")
	_assert("Mohinga" in inv_menu.item_title_label.text, "Item info card displays 'Mohinga'")
	_assert("FOOD" in inv_menu.item_category_badge.text, "Item info card category is FOOD")
	_assert("Hunger" in inv_menu.item_effects_label.text, "Item info card shows Hunger restoration effect")
	_assert(inv_menu.use_item_button.disabled == false, "Use Item button is enabled when item selected")

	# Use item action
	var nm := get_node_or_null("/root/NeedsManager")
	if nm:
		nm.hunger = 30.0
		inv_menu.use_selected_item()
		_assert(nm.hunger > 30.0, "use_selected_item() restored hunger in NeedsManager")

	# Close inventory
	inv_menu.close_inventory()
	_assert(inv_menu.visible == false, "close_inventory() hides inventory menu")
	_assert(inv_menu.is_open == false, "close_inventory() sets is_open = false")

	inv_menu.queue_free()

func test_start_screen() -> void:
	print("\n[M5 Sub-Suite 3: StartScreenController & start_screen.tscn]")
	var start_scene: PackedScene = load("res://scenes/ui/start_screen.tscn")
	_assert(start_scene != null, "scenes/ui/start_screen.tscn loaded successfully")

	var start_screen: StartScreenControllerScript = start_scene.instantiate() as StartScreenControllerScript
	_assert(start_screen != null, "start_screen.tscn instantiated as StartScreenController")
	_assert(start_screen is CanvasLayer, "StartScreenController extends CanvasLayer")
	_assert(start_screen.layer == 50, "StartScreen canvas layer is 50 (above gameplay)")
	add_child(start_screen)

	_assert(start_screen.title_label != null, "StartScreen has TitleLabel")
	_assert("YANGON LIFE" in start_screen.title_label.text, "Title text contains 'YANGON LIFE'")
	_assert(start_screen.subtitle_label != null, "StartScreen has SubtitleLabel")
	_assert(start_screen.instructions_card != null, "StartScreen has InstructionsCard with key controls")
	_assert(start_screen.start_button != null, "StartScreen has big StartButton")

	# Test start game trigger
	var signal_received: Array[bool] = [false]
	start_screen.game_started.connect(func() -> void: signal_received[0] = true)

	start_screen.start_game()
	_assert(signal_received[0] == true, "start_game() emitted game_started signal")
	_assert(start_screen.visible == false, "start_game() hid start screen overlay")

	start_screen.queue_free()

func test_pause_menu() -> void:
	print("\n[M5 Sub-Suite 4: PauseMenuController & pause_menu.tscn]")
	var pause_scene: PackedScene = load("res://scenes/ui/pause_menu.tscn")
	_assert(pause_scene != null, "scenes/ui/pause_menu.tscn loaded successfully")

	var pause_menu: PauseMenuControllerScript = pause_scene.instantiate() as PauseMenuControllerScript
	_assert(pause_menu != null, "pause_menu.tscn instantiated as PauseMenuController")
	_assert(pause_menu is Control, "PauseMenuController extends Control")
	add_child(pause_menu)

	# Initial state
	_assert(pause_menu.visible == false, "Pause menu is initially hidden")
	_assert(pause_menu.is_open == false, "pause_menu.is_open is false initially")

	# Open pause menu
	pause_menu.open_pause_menu()
	_assert(pause_menu.visible == true, "open_pause_menu() sets visible = true")
	_assert(pause_menu.is_open == true, "open_pause_menu() sets is_open = true")
	_assert(get_tree().paused == true, "open_pause_menu() pauses SceneTree")

	# Test Master Volume Slider
	pause_menu.volume_slider.value = 0.5
	pause_menu._on_volume_changed(0.5)
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		_assert(AudioServer.is_bus_mute(master_bus) == false, "AudioServer Master bus is unmuted at 50%")
		_assert(is_equal_approx(AudioServer.get_bus_volume_db(master_bus), linear_to_db(0.5)), "AudioServer master volume db matches linear 0.5")

	# Test Mouse Sensitivity Slider
	pause_menu.sensitivity_slider.value = 0.005
	pause_menu._on_sensitivity_changed(0.005)
	_assert(pause_menu.sensitivity_val_label.text == "0.0050", "Sensitivity label reflects 0.0050")

	# Test Save Action
	pause_menu.save_game_action()
	_assert(pause_menu.toast_label.visible == true, "Save button triggers toast label visibility")
	_assert("Saved" in pause_menu.toast_label.text, "Toast confirms 'Game Saved!'")

	# Test Resume Game
	pause_menu.resume_game()
	_assert(pause_menu.visible == false, "resume_game() hides pause menu")
	_assert(pause_menu.is_open == false, "resume_game() sets is_open = false")
	_assert(get_tree().paused == false, "resume_game() unpauses SceneTree")

	pause_menu.queue_free()
