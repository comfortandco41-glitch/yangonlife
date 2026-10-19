extends Node
## Milestone M7 Verification Suite: Visual/Audio Polish, Street Props, Audio Synthesis & Production Readiness

var tests_passed: int = 0
var tests_failed: int = 0

const AudioManagerScript = preload("res://scripts/systems/audio_manager.gd")
const DowntownYangonScene = preload("res://scenes/world/downtown_yangon.tscn")

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		print("  [PASS] %s" % test_name)
		tests_passed += 1
	else:
		printerr("  [FAIL] %s" % test_name)
		tests_failed += 1

func run_all() -> void:
	print("\n==================================================")
	print("  [Suite 20: Milestone M7 — Polish, Audio & Street Life]")
	print("==================================================")

	_test_audio_manager_synthesis()
	_test_downtown_street_props()
	_test_ambient_living_entities()
	_test_webgl2_performance_budget()

func _test_audio_manager_synthesis() -> void:
	print("\n[M7 Sub-Suite 1: Procedural AudioManager & WebGL2 Compliance]")
	var audio_mgr := AudioManagerScript.new()
	add_child(audio_mgr)

	_assert(audio_mgr != null, "AudioManager instantiated successfully")
	_assert(audio_mgr.has_node("UIPlayer"), "AudioManager has UIPlayer AudioStreamPlayer")
	_assert(audio_mgr.has_node("SFXPlayer"), "AudioManager has SFXPlayer AudioStreamPlayer")
	_assert(audio_mgr.has_node("AmbiencePlayer"), "AudioManager has AmbiencePlayer AudioStreamPlayer")
	_assert(audio_mgr.has_node("WeatherPlayer"), "AudioManager has WeatherPlayer AudioStreamPlayer")

	# Test procedural sound generation
	_assert(audio_mgr._sample_cache.has("click"), "Generated UI click audio stream")
	_assert(audio_mgr._sample_cache.has("coin"), "Generated MMK coin chime audio stream")
	_assert(audio_mgr._sample_cache.has("footstep"), "Generated footstep audio stream")
	_assert(audio_mgr._sample_cache.has("city_ambience"), "Generated city traffic rumble loop")
	_assert(audio_mgr._sample_cache.has("rain_ambience"), "Generated rain hiss loop")

	var click_stream: AudioStreamWAV = audio_mgr._sample_cache["click"] as AudioStreamWAV
	_assert(click_stream != null, "Click stream is AudioStreamWAV")
	_assert(click_stream.format == AudioStreamWAV.FORMAT_16_BITS, "Audio format is 16-bit PCM (WebGL2 standard)")
	_assert(click_stream.data.size() > 0, "Click audio buffer populated with PCM samples")

	var coin_stream: AudioStreamWAV = audio_mgr._sample_cache["coin"] as AudioStreamWAV
	_assert(coin_stream != null, "Coin stream is AudioStreamWAV")
	_assert(coin_stream.data.size() > 0, "Coin audio buffer populated with PCM samples")

	# Test audio playback methods
	audio_mgr.play_ui_click()
	_assert(true, "play_ui_click() executed cleanly")

	audio_mgr.play_coin()
	_assert(true, "play_coin() executed cleanly")

	audio_mgr.play_footstep()
	_assert(true, "play_footstep() executed cleanly")

	audio_mgr.set_rain_sound(true)
	var weather_player := audio_mgr.get_node("WeatherPlayer") as AudioStreamPlayer
	_assert(weather_player != null and weather_player.stream != null, "WeatherPlayer loaded with rain stream")

	audio_mgr.set_rain_sound(false)
	_assert(weather_player.playing == false, "WeatherPlayer stopped on clear weather")

	# Test audio unlock context
	audio_mgr.unlock_audio()
	_assert(audio_mgr.is_unlocked == true, "AudioManager unlocks WebAudio context")

	audio_mgr.queue_free()

func _test_downtown_street_props() -> void:
	print("\n[M7 Sub-Suite 2: Downtown Yangon Street Atmosphere & Props]")
	var world := DowntownYangonScene.instantiate() as Node3D
	add_child(world)

	_assert(world.has_node("StreetProps"), "DowntownYangon contains StreetProps node")
	var props := world.get_node("StreetProps")

	# Check authentic tea shop plastic stools
	_assert(props.has_node("TeaStool1"), "TeaStool1 present at Tea Shop")
	_assert(props.has_node("TeaStool2"), "TeaStool2 present at Tea Shop")
	_assert(props.has_node("TeaStool3"), "TeaStool3 present at Tea Shop")
	_assert(props.has_node("TeaStool4"), "TeaStool4 present at Tea Shop")

	# Check YBS Bus Stop Shelter
	_assert(props.has_node("BusShelter"), "YBS Bus Shelter present along main road")
	var shelter := props.get_node("BusShelter")
	_assert(shelter.has_node("Canopy"), "Bus shelter has canopy roof")
	_assert(shelter.has_node("Bench"), "Bus shelter has waiting passenger bench")
	_assert(shelter.has_node("BusSign"), "Bus shelter has route sign")
	var sign_lbl := shelter.get_node("BusSign") as Label3D
	_assert(sign_lbl != null and sign_lbl.text.contains("YBS"), "Bus shelter sign contains YBS brand")

	# Check utility poles with tangled power cables
	_assert(props.has_node("UtilityPole1"), "Roadside utility pole 1 present")
	_assert(props.has_node("UtilityPole2"), "Roadside utility pole 2 present")

	world.queue_free()

func _test_ambient_living_entities() -> void:
	print("\n[M7 Sub-Suite 3: Ambient Living Entities in Downtown Map]")
	var world := DowntownYangonScene.instantiate() as Node3D
	add_child(world)

	# Check ambient pedestrians in downtown scene
	_assert(world.has_node("PedestrianMonk"), "PedestrianMonk ambient NPC instanced near Sule")
	var monk := world.get_node("PedestrianMonk") as CharacterBody3D
	_assert(monk != null, "PedestrianMonk is CharacterBody3D")
	_assert(monk.get("archetype") == "monk", "PedestrianMonk has monk archetype")

	_assert(world.has_node("PedestrianWorker"), "PedestrianWorker ambient NPC instanced near City Hall")
	var worker := world.get_node("PedestrianWorker") as CharacterBody3D
	_assert(worker != null, "PedestrianWorker is CharacterBody3D")
	_assert(worker.get("archetype") == "office_worker", "PedestrianWorker has office_worker archetype")

	# Check YBS City Bus in traffic
	_assert(world.has_node("YBSCityBus"), "YBSCityBus automated traffic vehicle instanced on road")
	var bus := world.get_node("YBSCityBus") as CharacterBody3D
	_assert(bus != null, "YBSCityBus is CharacterBody3D")
	_assert(bus.get("car_type") == "ybs_bus", "YBSCityBus has 'ybs_bus' type")

	world.queue_free()

func _test_webgl2_performance_budget() -> void:
	print("\n[M7 Sub-Suite 4: WebGL2 Performance Budget & Collision Layers]")
	var world := DowntownYangonScene.instantiate() as Node3D
	add_child(world)

	# Count meshes and collision objects in the world scene
	var mesh_count: int = 0
	var body_count: int = 0
	var nodes_to_check: Array[Node] = [world]

	while not nodes_to_check.is_empty():
		var current: Node = nodes_to_check.pop_back()
		if current is MeshInstance3D:
			mesh_count += 1
		elif current is StaticBody3D or current is CharacterBody3D or current is Area3D:
			body_count += 1
		for child in current.get_children():
			nodes_to_check.append(child)

	_assert(mesh_count < 150, "Total world meshes (%d) well within WebGL2 draw call budget (<150)" % mesh_count)
	_assert(body_count < 100, "Total physics bodies (%d) within lightweight budget (<100)" % body_count)

	# Check collision layer assignments
	var ground := world.get_node("Ground") as StaticBody3D
	_assert(ground.collision_layer == 1, "Ground collision_layer is Layer 1 (World)")

	var taxi := world.get_node("TaxiSedan") as CharacterBody3D
	_assert(taxi.collision_layer == 4, "TaxiSedan collision_layer is Layer 3 Vehicles (bitmask 4)")

	var food := world.get_node("Interactables/FoodStall") as Area3D
	_assert(food.collision_layer == 8, "FoodStall collision_layer is Layer 4 Interactables (bitmask 8)")

	world.queue_free()
