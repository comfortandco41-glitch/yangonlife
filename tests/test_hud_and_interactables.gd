extends Node
## Automated verification test for HUD controller, InteractableZone, and interaction handlers

const InteractableZoneClass = preload("res://scripts/interaction/interactable_zone.gd")

func _ready() -> void:
	print("=== Running HUD & Interactables Verification Test ===")

	# 1. Test HUD Scene Loading and Initial State
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	assert(hud_scene != null, "HUD scene loads successfully")
	var hud := hud_scene.instantiate() as CanvasLayer
	add_child(hud)

	var money_label := hud.get_node("%MoneyLabel") as Label
	var time_label := hud.get_node("%TimeLabel") as Label
	var day_label := hud.get_node("%DayLabel") as Label
	var hunger_bar := hud.get_node("%HungerBar") as ProgressBar
	var energy_bar := hud.get_node("%EnergyBar") as ProgressBar
	var hygiene_bar := hud.get_node("%HygieneBar") as ProgressBar
	var stress_bar := hud.get_node("%StressBar") as ProgressBar
	var prompt_label := hud.get_node("%InteractionPrompt") as Label

	assert(money_label != null, "MoneyLabel exists")
	assert(time_label != null, "TimeLabel exists")
	assert(day_label != null, "DayLabel exists")
	assert(hunger_bar != null, "HungerBar exists")
	assert(energy_bar != null, "EnergyBar exists")
	assert(hygiene_bar != null, "HygieneBar exists")
	assert(stress_bar != null, "StressBar exists")
	assert(prompt_label != null, "InteractionPrompt exists")
	assert(prompt_label.visible == false, "Prompt initially hidden")

	print("[PASS] HUD components verified.")

	# 2. Test HUD Money Update
	EconomyManager.set_balance(75000)
	assert(money_label.text == "K 75,000", "Money label formatted correctly with comma: " + money_label.text)
	print("[PASS] HUD money formatting verified.")

	# 3. Test HUD Needs Update & Inverted Stress Bar
	NeedsManager.need_changed.emit("hunger", 45.0)
	assert(is_equal_approx(hunger_bar.value, 45.0), "Hunger bar value updated")

	NeedsManager.need_changed.emit("energy", 60.0)
	assert(is_equal_approx(energy_bar.value, 60.0), "Energy bar value updated")

	NeedsManager.need_changed.emit("hygiene", 85.0)
	assert(is_equal_approx(hygiene_bar.value, 85.0), "Hygiene bar value updated")

	NeedsManager.need_changed.emit("stress", 20.0)
	assert(is_equal_approx(stress_bar.value, 80.0), "Stress bar is inverted: 100 - 20 = 80")
	print("[PASS] HUD needs bars and inverted stress verified.")

	# 4. Test Time & Day Update
	TimeManager.set_time(14, 30, 3)
	assert(time_label.text == "14:30", "Time label displays 14:30")
	assert(day_label.text == "Day 3", "Day label displays Day 3")
	print("[PASS] HUD time and day display verified.")

	# 5. Test Interaction Prompt via InteractionManager signals
	InteractionManager.set_nearest_interactable(hud, "Buy Mohinga")
	assert(prompt_label.visible == true, "Prompt visible when interactable near")
	assert(prompt_label.text == "[E] Buy Mohinga", "Prompt text correctly formatted: " + prompt_label.text)

	InteractionManager.clear_interactable()
	assert(prompt_label.visible == false, "Prompt hidden when interactable cleared")
	print("[PASS] HUD interaction prompt verified.")

	# 6. Test InteractableZone & FoodStallHandler
	EconomyManager.set_balance(10000)
	NeedsManager.hunger = 30.0

	var food_stall_zone := InteractableZoneClass.new()
	food_stall_zone.prompt_text = "Buy Mohinga (3,000 MMK)"
	food_stall_zone.interaction_type = "food_stall"
	add_child(food_stall_zone)

	var food_handler_script: GDScript = load("res://scripts/interaction/food_stall_handler.gd")
	var food_handler: Node = food_handler_script.new()
	food_stall_zone.add_child(food_handler)

	var state := {"food_interacted": false}
	food_stall_zone.interacted.connect(func(): state["food_interacted"] = true)

	# Simulate interaction
	food_stall_zone.interact()
	assert(state["food_interacted"] == true, "Food stall emitted interacted signal")
	assert(EconomyManager.get_balance() == 7000, "Deducted 3,000 MMK for food")
	assert(is_equal_approx(NeedsManager.hunger, 70.0), "Hunger restored by 40.0")
	print("[PASS] FoodStallHandler verified.")

	# 7. Test TeaShopHandler
	var tea_shop_zone := InteractableZoneClass.new()
	tea_shop_zone.prompt_text = "Drink Tea (1,500 MMK)"
	tea_shop_zone.interaction_type = "tea_shop"
	add_child(tea_shop_zone)

	var tea_handler_script: GDScript = load("res://scripts/interaction/tea_shop_handler.gd")
	var tea_handler: Node = tea_handler_script.new()
	tea_shop_zone.add_child(tea_handler)

	NeedsManager.hunger = 50.0
	NeedsManager.stress = 40.0
	tea_shop_zone.interact()
	assert(EconomyManager.get_balance() == 5500, "Deducted 1,500 MMK for tea")
	assert(is_equal_approx(NeedsManager.hunger, 65.0), "Hunger restored by 15.0")
	assert(is_equal_approx(NeedsManager.stress, 30.0), "Stress reduced by 10.0")
	print("[PASS] TeaShopHandler verified.")

	# 8. Test ParkBenchHandler
	var bench_zone := InteractableZoneClass.new()
	bench_zone.prompt_text = "Sit on Park Bench"
	bench_zone.interaction_type = "park_bench"
	add_child(bench_zone)

	var bench_handler_script: GDScript = load("res://scripts/interaction/park_bench_handler.gd")
	var bench_handler: Node = bench_handler_script.new()
	bench_zone.add_child(bench_handler)

	bench_zone.interact()
	assert(EconomyManager.get_balance() == 5500, "Park bench is free")
	assert(is_equal_approx(NeedsManager.stress, 5.0), "Stress reduced by 25.0 (30 - 25 = 5)")
	print("[PASS] ParkBenchHandler verified.")

	# 9. Test JobBoardHandler
	CareerManager.quit_job()
	assert(CareerManager.current_job.is_empty(), "Player currently unemployed")

	var job_board_zone := InteractableZoneClass.new()
	job_board_zone.prompt_text = "View Job Board"
	job_board_zone.interaction_type = "job_board"
	add_child(job_board_zone)

	var job_handler_script: GDScript = load("res://scripts/interaction/job_board_handler.gd")
	var job_handler: Node = job_handler_script.new()
	job_board_zone.add_child(job_handler)

	job_board_zone.interact()
	assert(not CareerManager.current_job.is_empty(), "Accepted first job from CareerManager")
	print("[PASS] JobBoardHandler verified.")

	# 10. Test MainGame Scene Composition
	var main_scene: PackedScene = load("res://scenes/main/main_game.tscn")
	assert(main_scene != null, "Main game scene loads")
	var main_game := main_scene.instantiate() as Node3D
	add_child(main_game)

	var downtown := main_game.get_node_or_null("DowntownYangon")
	var player := main_game.get_node_or_null("Player") as Node3D
	var main_hud := main_game.get_node_or_null("HUD")

	assert(downtown != null, "DowntownYangon instanced in MainGame")
	assert(player != null, "Player instanced in MainGame")
	assert(main_hud != null, "HUD instanced in MainGame")
	assert(is_equal_approx(player.position.y, 1.0), "Player position Y is 1.0: " + str(player.position))
	print("[PASS] MainGame scene composition verified.")

	print("=== ALL TESTS PASSED SUCCESSFULLY! ===")
	get_tree().quit(0)
