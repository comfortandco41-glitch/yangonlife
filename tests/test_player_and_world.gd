extends SceneTree

func _init() -> void:
	print("--- Running Player & Downtown Yangon Verification ---")

	# 1. Test Player scene loading and instantiating
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	assert(player_scene != null, "player.tscn loaded successfully")
	var player_instance: Node = player_scene.instantiate()
	assert(player_instance != null, "player.tscn instantiated")
	assert(player_instance is CharacterBody3D, "Player is CharacterBody3D")
	assert(player_instance.is_in_group("player"), "Player is in 'player' group")

	var char_body := player_instance as CharacterBody3D
	assert(char_body.collision_layer == 2, "Collision layer is 2 (Characters)")
	assert(char_body.collision_mask == 13, "Collision mask is 13 (1|4|8)")

	# Check child nodes
	var col_shape: CollisionShape3D = player_instance.get_node_or_null("CollisionShape3D")
	assert(col_shape != null, "Player has CollisionShape3D")
	assert(col_shape.shape is CapsuleShape3D, "CollisionShape3D is CapsuleShape3D")

	var mesh_inst: MeshInstance3D = player_instance.get_node_or_null("PlayerMesh")
	assert(mesh_inst != null, "Player has PlayerMesh")
	assert(mesh_inst.mesh is CapsuleMesh, "PlayerMesh is CapsuleMesh")

	var cam_yaw: Node3D = player_instance.get_node_or_null("CameraYaw")
	assert(cam_yaw != null, "Player has CameraYaw")

	var spring_arm: SpringArm3D = player_instance.get_node_or_null("CameraYaw/SpringArm3D")
	assert(spring_arm != null, "CameraYaw has SpringArm3D")
	assert(is_equal_approx(spring_arm.spring_length, 4.0), "SpringArm length is 4.0")
	assert(spring_arm.collision_mask == 1, "SpringArm collision_mask is 1")

	var cam3d: Camera3D = player_instance.get_node_or_null("CameraYaw/SpringArm3D/Camera3D")
	assert(cam3d != null, "SpringArm has Camera3D")
	assert(cam3d.current == true, "Camera3D is current")
	assert(is_equal_approx(cam3d.fov, 70.0), "Camera3D fov is 70")

	# Test player controller save/load methods
	assert(player_instance.has_method("get_save_data"), "Has get_save_data")
	assert(player_instance.has_method("load_save_data"), "Has load_save_data")
	var save_dict: Dictionary = player_instance.call("get_save_data")
	assert(save_dict.has("position"), "Save data has position")
	assert(save_dict["position"] is Array, "Position is Array")

	player_instance.call("load_save_data", {"position": [10.0, 2.0, -15.0], "rotation_y": 1.57})
	var check_pos: Vector3 = char_body.global_position if char_body.is_inside_tree() else char_body.position
	assert(is_equal_approx(check_pos.x, 10.0), "Loaded position X")
	assert(is_equal_approx(check_pos.y, 2.0), "Loaded position Y")
	assert(is_equal_approx(check_pos.z, -15.0), "Loaded position Z")
	assert(is_equal_approx(char_body.rotation.y, 1.57), "Loaded rotation Y")

	player_instance.free()
	print("✓ Player scene and controller verification PASSED!")

	# 2. Test Downtown Yangon scene loading and instantiating
	var world_scene: PackedScene = load("res://scenes/world/downtown_yangon.tscn")
	assert(world_scene != null, "downtown_yangon.tscn loaded successfully")
	var world_instance: Node = world_scene.instantiate()
	assert(world_instance != null, "downtown_yangon.tscn instantiated")
	assert(world_instance.name == "DowntownYangon", "Root name is DowntownYangon")

	# Check DirectionalLight3D
	var sun: DirectionalLight3D = world_instance.get_node_or_null("DirectionalLight3D")
	assert(sun != null, "DirectionalLight3D exists")
	assert(sun.shadow_enabled == true, "Shadows enabled")

	# Check WorldEnvironment
	var env: WorldEnvironment = world_instance.get_node_or_null("WorldEnvironment")
	assert(env != null, "WorldEnvironment exists")
	assert(env.environment != null, "Environment set")

	# Check Ground
	var ground: StaticBody3D = world_instance.get_node_or_null("Ground")
	assert(ground != null, "Ground exists")
	assert(ground.get_node_or_null("CollisionShape3D") != null, "Ground has CollisionShape3D")
	assert(ground.get_node_or_null("MeshInstance3D") != null, "Ground has MeshInstance3D")

	# Check Roads
	var roads: Node3D = world_instance.get_node_or_null("Roads")
	assert(roads != null, "Roads node exists")
	assert(roads.get_node_or_null("MainRoad_NS") != null, "MainRoad_NS exists")
	assert(roads.get_node_or_null("MainRoad_EW") != null, "MainRoad_EW exists")
	assert(roads.get_node_or_null("SideStreet1") != null, "SideStreet1 exists")
	assert(roads.get_node_or_null("SideStreet2") != null, "SideStreet2 exists")

	# Check Buildings
	var buildings: Node3D = world_instance.get_node_or_null("Buildings")
	assert(buildings != null, "Buildings node exists")
	var building_names := [
		"ColonialBlock_A", "ColonialBlock_B", "Shophouse_A", "Shophouse_B",
		"OfficeBuilding", "Market_Hall", "Temple", "Apartment_A"
	]
	for b_name in building_names:
		var b: StaticBody3D = buildings.get_node_or_null(b_name)
		assert(b != null, "Building %s exists" % b_name)
		assert(b.collision_layer == 1, "Building %s has layer 1" % b_name)
		var b_col: CollisionShape3D = b.get_node_or_null("CollisionShape3D")
		var b_mesh: MeshInstance3D = b.get_node_or_null("MeshInstance3D")
		assert(b_col != null, "Building %s has CollisionShape3D" % b_name)
		assert(b_mesh != null, "Building %s has MeshInstance3D" % b_name)

	# Check Interactables
	var interactables: Node3D = world_instance.get_node_or_null("Interactables")
	assert(interactables != null, "Interactables node exists")
	var area_names := ["FoodStall", "TeaShop", "JobBoard"]
	for a_name in area_names:
		var a: Area3D = interactables.get_node_or_null(a_name)
		assert(a != null, "Interactable %s exists" % a_name)
		assert(a.collision_layer == 8, "Interactable %s collision_layer is 8 (Physics layer 4)" % a_name)
		assert(a.get_node_or_null("CollisionShape3D") != null, "%s has CollisionShape3D" % a_name)
		assert(a.get_node_or_null("MeshInstance3D") != null, "%s has MeshInstance3D" % a_name)
		assert(a.get_node_or_null("Label3D") != null, "%s has Label3D" % a_name)

	# Check Park
	var park: Node3D = world_instance.get_node_or_null("Park")
	assert(park != null, "Park node exists")
	assert(park.get_node_or_null("ParkGround") != null, "ParkGround exists")
	var bench: Area3D = park.get_node_or_null("ParkBench")
	assert(bench != null, "ParkBench exists")
	assert(bench.collision_layer == 8, "ParkBench collision_layer is 8 (Physics layer 4)")
	assert(bench.get_node_or_null("CollisionShape3D") != null, "ParkBench has CollisionShape3D")
	assert(bench.get_node_or_null("MeshInstance3D") != null, "ParkBench has MeshInstance3D")
	assert(bench.get_node_or_null("Label3D") != null, "ParkBench has Label3D")

	# Check SpawnPoint
	var spawn: Node3D = world_instance.get_node_or_null("SpawnPoint")
	assert(spawn != null, "SpawnPoint exists")

	world_instance.free()
	print("✓ Downtown Yangon scene verification PASSED!")

	print("--- ALL VERIFICATION TESTS PASSED SUCCESSFULLY! ---")
	quit(0)
