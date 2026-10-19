extends SceneTree
# Automated Headless Test Suite for Yangon Frontline

var tests_passed: int = 0
var tests_failed: int = 0

func _init() -> void:
	process_frame.connect(_run_deferred_tests, CONNECT_ONE_SHOT)

func _run_deferred_tests() -> void:
	print("==================================================")
	print("  YANGON FRONTLINE — AUTOMATED HEADLESS TESTS    ")
	print("==================================================")

	_run_all_tests()

	print("\n--------------------------------------------------")
	print("TEST RESULTS: %d PASSED, %d FAILED" % [tests_passed, tests_failed])
	print("--------------------------------------------------")

	if tests_failed == 0:
		print(">> ALL SYSTEMS VERIFIED SUCCESSFULLY! <<\n")
		quit(0)
	else:
		printerr(">> TEST FAILURES DETECTED! <<\n")
		quit(1)

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		print("  [PASS] %s" % test_name)
		tests_passed += 1
	else:
		printerr("  [FAIL] %s" % test_name)
		tests_failed += 1

func _run_all_tests() -> void:
	_test_health_component()
	_test_hitbox_friendly_fire()
	_test_weapon_mechanics()
	_test_scene_instantiations()
	_test_ai_state_machine()
	_test_mission_objective_logic()

func _test_health_component() -> void:
	print("\n[Suite 1: HealthComponent]")
	var health = HealthComponent.new()
	health.max_health = 100.0
	health.current_health = 100.0

	health.take_damage(30.0, 1)
	_assert(is_equal_approx(health.current_health, 70.0), "Damage reduces health correctly (100 -> 70)")
	_assert(not health.is_dead, "Entity alive after non-lethal damage")

	var died_signal_fired = [false]
	health.died.connect(func(_killer): died_signal_fired[0] = true)
	health.take_damage(80.0, 1)
	_assert(is_equal_approx(health.current_health, 0.0), "Health clamps to 0 on lethal damage")
	_assert(health.is_dead, "Entity marked dead on lethal damage")
	_assert(died_signal_fired[0], "died signal emitted on death")

	health.heal(50.0)
	_assert(health.is_dead and is_equal_approx(health.current_health, 0.0), "Dead entity cannot be healed without reset")

	health.reset()
	_assert(not health.is_dead and is_equal_approx(health.current_health, 100.0), "reset() restores full health and alive status")
	health.free()

func _test_hitbox_friendly_fire() -> void:
	print("\n[Suite 2: HitboxComponent & Friendly Fire]")
	var health = HealthComponent.new()
	health.max_health = 100.0
	health.current_health = 100.0
	health.team_id = 2 # PDF

	var hitbox = HitboxComponent.new()
	hitbox.health_component = health
	hitbox.team_id = 2 # PDF
	hitbox.damage_multiplier = 1.0
	hitbox.allow_friendly_fire = false

	# Friendly fire shot (PDF shooting PDF)
	var friendly_hit = hitbox.receive_damage(25.0, 2)
	_assert(not friendly_hit, "Friendly fire rejected when allow_friendly_fire=false")
	_assert(is_equal_approx(health.current_health, 100.0), "Ally health unchanged after friendly shot")

	# Hostile fire shot (MILITARY shooting PDF)
	var hostile_hit = hitbox.receive_damage(25.0, 1)
	_assert(hostile_hit, "Hostile fire accepted")
	_assert(is_equal_approx(health.current_health, 75.0), "Target health reduced by hostile shot")

	hitbox.free()
	health.free()

func _test_weapon_mechanics() -> void:
	print("\n[Suite 3: WeaponManager Mechanics]")
	var weap = WeaponManager.new()
	weap.mag_capacity = 30
	weap.current_ammo = 30
	weap.reserve_ammo = 60
	weap.damage = 25.0
	weap.fire_rate = 0.0 # instant for test
	weap.time_since_last_shot = 1.0
	weap.can_fire = true

	_assert(weap.can_shoot(), "Weapon reports can_shoot() when loaded")

	var shot_fired = weap.shoot()
	_assert(shot_fired, "shoot() succeeds")
	_assert(weap.current_ammo == 29, "shoot() decrements magazine ammo (30 -> 29)")

	weap.current_ammo = 0
	_assert(not weap.can_shoot(), "Weapon cannot shoot when magazine is empty")

	weap.free()

func _test_scene_instantiations() -> void:
	print("\n[Suite 4: Scene Instantiations]")
	var scenes_to_test = [
		"res://scenes/weapons/bullet_tracer.tscn",
		"res://scenes/player/player.tscn",
		"res://scenes/characters/ai_soldier.tscn",
		"res://scenes/environment/yangon_arena.tscn",
		"res://scenes/ui/hud.tscn",
		"res://scenes/main/main_game.tscn"
	]

	for path in scenes_to_test:
		var packed = load(path) as PackedScene
		_assert(packed != null, "Scene resource loads: " + path.get_file())
		if packed:
			var instance = packed.instantiate()
			_assert(instance != null, "Scene instantiates cleanly: " + path.get_file())
			instance.free()

func _test_ai_state_machine() -> void:
	print("\n[Suite 5: AISoldier FSM]")
	var ai_scene = load("res://scenes/characters/ai_soldier.tscn") as PackedScene
	var ai = ai_scene.instantiate() as AISoldier
	root.add_child(ai)

	_assert(ai.current_state == AISoldier.State.IDLE, "AISoldier initializes in IDLE state")
	_assert(ai.team_id == 1, "AISoldier assigned to MILITARY team (team_id=1)")
	_assert(ai.health_component != null, "AISoldier contains valid HealthComponent")

	# Simulate lethal damage
	ai.health_component.take_damage(100.0, 2)
	_assert(ai.current_state == AISoldier.State.DEAD, "AISoldier enters DEAD state upon lethal damage")

	ai.queue_free()

func _test_mission_objective_logic() -> void:
	print("\n[Suite 6: Mission Objective Logic]")
	var mission_scene = load("res://scenes/main/main_game.tscn") as PackedScene
	var mission = mission_scene.instantiate() as MissionClearSector
	root.add_child(mission)

	_assert(mission.total_enemies == 3, "Mission initialized with 3 hostile patrol units")
	_assert(mission.remaining_enemies == 3, "Mission tracks 3 active remaining enemies")
	_assert(mission.is_mission_active, "Mission is currently active")

	var enemies_container = mission.get_node("Enemies") as Node3D
	_assert(enemies_container != null, "Enemies container node exists in mission")

	var enemies = enemies_container.get_children()
	_assert(enemies.size() == 3, "Enemies container has 3 instantiated soldiers")

	for enemy in enemies:
		if enemy is AISoldier:
			enemy.health_component.take_damage(100.0, 2)

	_assert(mission.remaining_enemies == 0, "All enemies eliminated (remaining=0)")
	_assert(not mission.is_mission_active, "Mission completed upon neutralising all enemies")
	_assert(mission.hud.victory_panel.visible, "Victory panel displayed upon sector clearance")

	mission.queue_free()
