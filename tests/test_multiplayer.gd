extends SceneTree
## Milestone M6: WebSocket Multiplayer Test Suite for Yangon Life (ရန်ကုန် ဘဝ)
## Verifies NetworkManager, RemotePlayer puppet, ServerMain, and WebSocket loopback.

var tests_passed: int = 0
var tests_failed: int = 0

const NetworkManagerScript = preload("res://scripts/networking/network_manager.gd")
const RemotePlayerScript = preload("res://scripts/networking/remote_player.gd")
const ServerMainScript = preload("res://server/server_main.gd")
const TEST_PORT: int = 8918

var _nm: NetworkManager
var _server_node: Node

func _init() -> void:
	process_frame.connect(_run_all_tests, CONNECT_ONE_SHOT)

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		print("  [PASS] %s" % test_name)
		tests_passed += 1
	else:
		printerr("  [FAIL] %s" % test_name)
		tests_failed += 1

func _setup() -> void:
	if root.has_node("NetworkManager"):
		_nm = root.get_node("NetworkManager") as NetworkManager
	else:
		_nm = NetworkManagerScript.new()
		_nm.name = "NetworkManager"
		root.add_child(_nm)

func _run_all_tests() -> void:
	print("==================================================")
	print("  MILESTONE M6: WEBSOCKET MULTIPLAYER TEST SUITE  ")
	print("==================================================")
	
	_setup()
	
	_test_network_manager_constants_and_state()
	_test_server_lifecycle()
	_test_server_authoritative_economy()
	_test_kinematics_and_transform_sync()
	_test_chat_rpc_system()
	_test_remote_player_puppet_and_scene()
	_test_server_headless_scene()
	_test_websocket_network_loopback()

func _test_network_manager_constants_and_state() -> void:
	print("\n[Suite 1: NetworkManager Constants & Initial State]")
	_assert(NetworkManager.DEFAULT_PORT == 8910, "DEFAULT_PORT is 8910")
	_assert(NetworkManager.MAX_PLAYERS == 8, "MAX_PLAYERS is 8")
	_assert(is_equal_approx(NetworkManager.TICK_RATE_HZ, 20.0), "TICK_RATE_HZ is 20.0 Hz")
	_assert(is_equal_approx(NetworkManager.TICK_INTERVAL, 0.05), "TICK_INTERVAL is 0.05s (50ms)")
	
	_assert(_nm.is_server == false, "Initially is_server is false")
	_assert(_nm.is_connected_to_server == false, "Initially is_connected_to_server is false")
	_assert(_nm.connected_players is Dictionary, "connected_players is a Dictionary")
	_assert(_nm.get_player_count() == 0, "Initial player count is 0")

func _test_server_lifecycle() -> void:
	print("\n[Suite 2: Server Lifecycle & State Transitions]")
	var started_signal := [false]
	var started_port := [0]
	var server_cb = func(port: int):
		started_signal[0] = true
		started_port[0] = port
	
	_nm.server_started.connect(server_cb, CONNECT_ONE_SHOT)
	var started: bool = _nm.start_server(TEST_PORT)
	
	_assert(started == true, "start_server(%d) returns true" % TEST_PORT)
	_assert(_nm.is_server == true, "is_server is true while server is active")
	_assert(_nm.is_connected_to_server == false, "is_connected_to_server is false on server")
	_assert(started_signal[0] == true, "server_started signal was emitted")
	_assert(started_port[0] == TEST_PORT, "server_started signal emitted correct port: %d" % TEST_PORT)
	
	var stopped_signal := [false]
	var stop_cb = func(): stopped_signal[0] = true
	_nm.server_stopped.connect(stop_cb, CONNECT_ONE_SHOT)
	
	_nm.disconnect_network()
	_assert(_nm.is_server == false, "is_server is false after disconnect_network()")
	_assert(stopped_signal[0] == true, "server_stopped signal was emitted")
	_assert(_nm.get_player_count() == 0, "connected_players cleared on disconnect")

func _test_server_authoritative_economy() -> void:
	print("\n[Suite 3: Server-Authoritative Economy & Zero-Trust Validation]")
	_nm.start_server(TEST_PORT)
	
	# Simulate registered player (Peer ID 2) with 50,000 MMK
	_nm.connected_players[2] = {
		"name": "Ma Su",
		"position": Vector3.ZERO,
		"rotation_y": 0.0,
		"balance": 50000
	}
	
	var tx_events: Array[Dictionary] = []
	var tx_handler = func(pid: int, amount: int, new_bal: int, reason: String, success: bool):
		tx_events.append({
			"peer_id": pid,
			"amount": amount,
			"new_balance": new_bal,
			"reason": reason,
			"success": success
		})
	_nm.transaction_processed.connect(tx_handler)
	
	# 1. Valid purchase deduction (3,000 MMK for lunch)
	_nm.connected_players[1] = {"name": "Host", "position": Vector3.ZERO, "rotation_y": 0.0, "balance": 50000}
	# Call transaction on peer 1 (local host)
	_nm.request_transaction(-3000, "Shan Noodles Lunch")
	_assert(tx_events.size() == 1, "Transaction processed event emitted")
	_assert(tx_events[0]["success"] == true, "3,000 MMK purchase approved")
	_assert(tx_events[0]["new_balance"] == 47000, "Authoritative balance updated to 47,000 MMK")
	_assert(_nm.connected_players[1]["balance"] == 47000, "Server stored balance is 47,000 MMK")
	
	# 2. Overdraft attempt (100,000 MMK purchase when balance is 47,000 MMK)
	_nm.request_transaction(-100000, "Luxury Item")
	_assert(tx_events.size() == 2, "Overdraft transaction processed event emitted")
	_assert(tx_events[1]["success"] == false, "Overdraft transaction rejected (success=false)")
	_assert(tx_events[1]["new_balance"] == 47000, "Balance preserved at 47,000 MMK after rejected overdraft")
	_assert(_nm.connected_players[1]["balance"] == 47000, "Server record unchanged after overdraft")
	
	# 3. Positive purchase description should also be treated as debit
	_nm.request_transaction(100000, "Expensive Jewelry Purchase")
	_assert(tx_events.size() == 3, "Purchase reason transaction event emitted")
	_assert(tx_events[2]["success"] == false, "100,000 MMK purchase rejected due to overdraft")
	_assert(_nm.connected_players[1]["balance"] == 47000, "Balance still 47,000 MMK")
	
	# 4. Valid wage credit (8,000 MMK)
	_nm.request_transaction(8000, "Delivery Shift Wage")
	_assert(tx_events.size() == 4, "Wage transaction event emitted")
	_assert(tx_events[3]["success"] == true, "Wage addition approved")
	_assert(tx_events[3]["new_balance"] == 55000, "Balance credited to 55,000 MMK (47,000 + 8,000)")
	_assert(_nm.connected_players[1]["balance"] == 55000, "Server stored balance updated to 55,000 MMK")
	
	_nm.transaction_processed.disconnect(tx_handler)
	_nm.disconnect_network()

func _test_kinematics_and_transform_sync() -> void:
	print("\n[Suite 4: Kinematics & 20 Hz Transform Sync]")
	_nm.start_server(TEST_PORT)
	_nm.connected_players[1] = {
		"name": "TestHost",
		"position": Vector3.ZERO,
		"rotation_y": 0.0,
		"balance": 50000
	}
	
	var transform_updated := [false]
	var updated_pos := [Vector3.ZERO]
	var updated_rot := [0.0]
	var tf_handler = func(pid: int, pos: Vector3, rot: float):
		transform_updated[0] = true
		updated_pos[0] = pos
		updated_rot[0] = rot
	_nm.player_transform_updated.connect(tf_handler)
	
	var target_pos := Vector3(12.5, 0.0, -45.2)
	var target_rot_y := 1.5708 # 90 degrees
	_nm.sync_player_transform(target_pos, target_rot_y)
	
	_assert(transform_updated[0] == true, "player_transform_updated signal emitted")
	_assert(updated_pos[0].is_equal_approx(target_pos), "Synced position matches target position")
	_assert(is_equal_approx(updated_rot[0], target_rot_y), "Synced rotation Y matches target rotation Y")
	_assert(_nm.connected_players[1]["position"] == target_pos, "Server player record updated with position")
	_assert(is_equal_approx(_nm.connected_players[1]["rotation_y"], target_rot_y), "Server player record updated with rotation Y")
	
	_nm.player_transform_updated.disconnect(tf_handler)
	_nm.disconnect_network()

func _test_chat_rpc_system() -> void:
	print("\n[Suite 5: Chat RPC System]")
	var chat_received := [false]
	var chat_sender := [""]
	var chat_text := [""]
	var chat_handler = func(s_name: String, msg: String):
		chat_received[0] = true
		chat_sender[0] = s_name
		chat_text[0] = msg
	_nm.chat_received.connect(chat_handler)
	
	_nm.send_chat("Ko Kyaw", "Mingalaba! Let's get tea.")
	_assert(chat_received[0] == true, "chat_received emitted via send_chat")
	_assert(chat_sender[0] == "Ko Kyaw", "Sender name matches 'Ko Kyaw'")
	_assert(chat_text[0] == "Mingalaba! Let's get tea.", "Message content preserved")
	
	# Test sanitization: empty name defaults to Anonymous
	chat_received[0] = false
	_nm.send_chat("   ", "Hello Yangon")
	_assert(chat_sender[0] == "Anonymous", "Empty sender name sanitized to 'Anonymous'")
	
	# Test clamping: message length clamped to 250 characters
	var long_msg: String = "X".repeat(300)
	_nm.send_chat("Tester", long_msg)
	_assert(chat_text[0].length() == 250, "Long chat message clamped to 250 characters")
	
	_nm.chat_received.disconnect(chat_handler)

func _test_remote_player_puppet_and_scene() -> void:
	print("\n[Suite 6: RemotePlayer Puppet & Scene]")
	var remote_scene: PackedScene = load("res://scenes/player/remote_player.tscn")
	_assert(remote_scene != null, "scenes/player/remote_player.tscn loaded successfully")
	
	var puppet: CharacterBody3D = remote_scene.instantiate() as CharacterBody3D
	_assert(puppet != null, "remote_player.tscn instantiated cleanly")
	_assert(puppet is RemotePlayer, "Puppet is an instance of RemotePlayer class")
	_assert(puppet.is_in_group("remote_player"), "Puppet added to 'remote_player' group")
	_assert(puppet.collision_layer == 2, "Puppet collision_layer = 2 (Characters)")
	_assert(puppet.collision_mask == 1, "Puppet collision_mask = 1 (World)")
	
	# Visual hierarchy
	_assert(puppet.has_node("CollisionShape3D"), "Puppet has CollisionShape3D")
	_assert(puppet.has_node("BodyMesh"), "Puppet has BodyMesh (Burmese shirt/eingyi)")
	_assert(puppet.has_node("LongyiMesh"), "Puppet has LongyiMesh (Colored longyi)")
	_assert(puppet.has_node("OverheadLabel"), "Puppet has OverheadLabel")
	
	var label := puppet.get_node("OverheadLabel") as Label3D
	_assert(label != null, "OverheadLabel is a Label3D")
	_assert(label.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "OverheadLabel has billboard mode enabled")
	
	# Set player data and check label formatting
	puppet.set_player_name("Ko Aung")
	puppet.set_player_balance(65000)
	puppet.set_player_status("Tea Stall")
	_assert(label.text.contains("Ko Aung"), "Overhead label displays player name 'Ko Aung'")
	_assert(label.text.contains("K 65,000"), "Overhead label displays formatted MMK balance 'K 65,000'")
	_assert(label.text.contains("Tea Stall"), "Overhead label displays status 'Tea Stall'")
	
	# Kinematic Cubic Hermite Interpolation
	root.add_child(puppet)
	puppet.global_position = Vector3(0.0, 0.0, 0.0)
	puppet.rotation.y = 0.0
	
	var target_pos := Vector3(4.0, 0.0, 0.0)
	var target_rot := 1.5708 # 90 deg
	puppet.set_target_transform(target_pos, target_rot)
	
	# Halfway through 50ms tick (at 25ms):
	puppet._process(0.025)
	# At t = 0.5: smoothstep is 3*(0.25) - 2*(0.125) = 0.75 - 0.25 = 0.5
	_assert(puppet.global_position.x > 0.5 and puppet.global_position.x < 3.5, "Puppet smoothly interpolated halfway along X axis")
	_assert(puppet.rotation.y > 0.2 and puppet.rotation.y < 1.4, "Puppet smoothly interpolated rotation Y")
	
	# Complete interpolation
	puppet._process(0.030)
	_assert(puppet.global_position.is_equal_approx(target_pos), "Puppet reached target position smoothly")
	_assert(is_equal_approx(puppet.rotation.y, target_rot), "Puppet reached target rotation Y")
	
	# Teleport threshold snap (> 8.0 meters)
	var far_pos := Vector3(100.0, 0.0, 50.0)
	puppet.set_target_transform(far_pos, 0.0)
	_assert(puppet.global_position.is_equal_approx(far_pos), "Teleport (> 8m) snaps immediately without interpolation lag")
	
	puppet.queue_free()

func _test_server_headless_scene() -> void:
	print("\n[Suite 7: Headless Server Scene & ServerMain]")
	var server_scene: PackedScene = load("res://server/server.tscn")
	_assert(server_scene != null, "server/server.tscn loaded successfully")
	
	var server_root := server_scene.instantiate() as Node
	_assert(server_root != null, "server.tscn instantiated cleanly")
	_assert(server_root.name == "ServerRoot", "Root node named 'ServerRoot'")
	_assert(server_root is ServerMain, "server_root script is ServerMain")
	
	# Check methods and state
	_assert(server_root.has_method("_simulate_city_tick"), "ServerMain has _simulate_city_tick")
	_assert(server_root.has_method("_log_server_heartbeat"), "ServerMain has _log_server_heartbeat")
	_assert("DEFAULT_SERVER_PORT" in server_root, "DEFAULT_SERVER_PORT constant present")
	_assert("CITY_TICK_INTERVAL" in server_root, "CITY_TICK_INTERVAL constant present")
	
	server_root.free()

func _test_websocket_network_loopback() -> void:
	print("\n[Suite 8: WebSocket Client-Server Network Loopback]")
	# Start authoritative server on test port
	var server_ok: bool = _nm.start_server(TEST_PORT)
	_assert(server_ok == true, "WebSocket server started for loopback test")
	
	# Create a standalone client peer to verify WebSocketMultiplayerPeer connectivity
	var client_peer := WebSocketMultiplayerPeer.new()
	var client_err: Error = client_peer.create_client("ws://127.0.0.1:%d" % TEST_PORT)
	_assert(client_err == OK, "WebSocket client created connecting to ws://127.0.0.1:%d" % TEST_PORT)
	
	# Poll for connection
	var connected := false
	for frame in range(60):
		_nm._peer.poll()
		client_peer.poll()
		if client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			connected = true
			break
	
	_assert(connected == true, "WebSocket client successfully connected to server over loopback!")
	
	client_peer.close()
	_nm.disconnect_network()
	
	print("\n--------------------------------------------------")
	print("TEST RESULTS: %d PASSED, %d FAILED" % [tests_passed, tests_failed])
	print("--------------------------------------------------")
	
	if tests_failed == 0:
		print(">> ALL MULTIPLAYER (M6) SYSTEMS VERIFIED CLEANLY! <<\n")
		quit(0)
	else:
		printerr(">> MULTIPLAYER (M6) TESTS FAILED! <<\n")
		quit(1)
