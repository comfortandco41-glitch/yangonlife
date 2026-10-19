extends Node
## Multiplayer Network Coordinator for Yangon Life (ရန်ကုန် ဘဝ).
##
## Manages WebSocketMultiplayerPeer connections, cross-play between desktop and WebGL2 browsers,
## 20 Hz player transform replication, server-authoritative economy validation, and chat.

signal server_started(port: int)
signal server_stopped
signal client_connected
signal client_connection_failed
signal server_disconnected
signal player_joined(peer_id: int, player_name: String)
signal player_left(peer_id: int)
signal player_transform_updated(peer_id: int, pos: Vector3, rot_y: float)
signal chat_received(sender_name: String, message: String)
signal transaction_processed(peer_id: int, amount: int, new_balance: int, reason: String, success: bool)
signal balance_updated(peer_id: int, new_balance: int)

const DEFAULT_PORT: int = 8910
const MAX_PLAYERS: int = 8
const TICK_RATE_HZ: float = 20.0
const TICK_INTERVAL: float = 1.0 / TICK_RATE_HZ # 0.05 seconds

var is_server: bool = false
var is_connected_to_server: bool = false
var connected_players: Dictionary = {} # peer_id (int) -> {"name": String, "position": Vector3, "rotation_y": float, "balance": int}

var local_player_name: String = "Player"
var remote_players: Dictionary = {} # peer_id (int) -> CharacterBody3D
var remote_players_container: Node3D = null

var _peer: WebSocketMultiplayerPeer = null
var _tick_accumulator: float = 0.0
var _remote_player_scene: PackedScene = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_remote_player_scene = load("res://scenes/player/remote_player.tscn")
	_ensure_remote_container()

func _physics_process(delta: float) -> void:
	if is_connected_to_server and not is_server:
		_tick_accumulator += delta
		if _tick_accumulator >= TICK_INTERVAL:
			_tick_accumulator -= TICK_INTERVAL
			_sync_local_player()

func _ensure_remote_container() -> void:
	if remote_players_container == null or not is_instance_valid(remote_players_container):
		if has_node("RemotePlayers"):
			remote_players_container = get_node("RemotePlayers") as Node3D
		else:
			remote_players_container = Node3D.new()
			remote_players_container.name = "RemotePlayers"
			add_child(remote_players_container)

## Starts dedicated headless WebSocket server on the specified port.
func start_server(port: int = DEFAULT_PORT) -> bool:
	disconnect_network()
	
	_peer = WebSocketMultiplayerPeer.new()
	var err: Error = _peer.create_server(port)
	if err != OK:
		printerr("[NetworkManager] Failed to create server on port %d: %s" % [port, error_string(err)])
		_peer = null
		return false
	
	multiplayer.multiplayer_peer = _peer
	is_server = true
	is_connected_to_server = false
	
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# Register host entity for server if applicable
	connected_players.clear()
	
	print("[NetworkManager] Server started on port %d (Max %d players, %0.1f Hz tick rate)" % [port, MAX_PLAYERS, TICK_RATE_HZ])
	server_started.emit(port)
	return true

## Connects to a WebSocket server at the given address and port.
func connect_to_server(address: String = "127.0.0.1", port: int = DEFAULT_PORT) -> bool:
	disconnect_network()
	
	_peer = WebSocketMultiplayerPeer.new()
	var url: String = address
	if not (url.begins_with("ws://") or url.begins_with("wss://")):
		url = "ws://%s:%d" % [address, port]
	
	var err: Error = _peer.create_client(url)
	if err != OK:
		printerr("[NetworkManager] Failed to connect to server at %s: %s" % [url, error_string(err)])
		_peer = null
		client_connection_failed.emit()
		return false
	
	multiplayer.multiplayer_peer = _peer
	is_server = false
	is_connected_to_server = false
	
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	print("[NetworkManager] Connecting to server at %s..." % url)
	return true

## Disconnects current session, frees all remote puppets, and resets state.
func disconnect_network() -> void:
	if multiplayer.has_multiplayer_peer():
		if multiplayer.connected_to_server.is_connected(_on_connected_to_server):
			multiplayer.connected_to_server.disconnect(_on_connected_to_server)
		if multiplayer.connection_failed.is_connected(_on_connection_failed):
			multiplayer.connection_failed.disconnect(_on_connection_failed)
		if multiplayer.server_disconnected.is_connected(_on_server_disconnected):
			multiplayer.server_disconnected.disconnect(_on_server_disconnected)
		if multiplayer.peer_connected.is_connected(_on_peer_connected):
			multiplayer.peer_connected.disconnect(_on_peer_connected)
		if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
			multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)
	
	if _peer != null:
		_peer.close()
		_peer = null
	
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer = null
	
	clear_all_remote_players()
	connected_players.clear()
	
	var was_server: bool = is_server
	is_server = false
	is_connected_to_server = false
	_tick_accumulator = 0.0
	
	if was_server:
		server_stopped.emit()
	else:
		server_disconnected.emit()

# ==============================================================================
# MULTIPLAYER EVENT HANDLERS
# ==============================================================================

func _on_peer_connected(peer_id: int) -> void:
	print("[NetworkManager] Peer connected: %d" % peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	print("[NetworkManager] Peer disconnected: %d" % peer_id)
	if is_server:
		if connected_players.has(peer_id):
			connected_players.erase(peer_id)
		notify_player_left.rpc(peer_id)
		player_left.emit(peer_id)
	else:
		if connected_players.has(peer_id):
			connected_players.erase(peer_id)
		despawn_remote_player(peer_id)
		player_left.emit(peer_id)

func _on_connected_to_server() -> void:
	is_connected_to_server = true
	var unique_id: int = multiplayer.get_unique_id()
	print("[NetworkManager] Connected to server! Assigned Peer ID: %d" % unique_id)
	client_connected.emit()
	
	# Register player identity with server
	register_player.rpc_id(1, local_player_name)

func _on_connection_failed() -> void:
	is_connected_to_server = false
	printerr("[NetworkManager] Connection to server failed.")
	client_connection_failed.emit()

func _on_server_disconnected() -> void:
	print("[NetworkManager] Server disconnected.")
	disconnect_network()

# ==============================================================================
# RPC METHODS & REPLICATION
# ==============================================================================

## Client registers its player identity with the server.
@rpc("any_peer", "call_remote", "reliable")
func register_player(player_name: String) -> void:
	if not is_server:
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	
	# Enforce server player capacity limit
	if connected_players.size() >= MAX_PLAYERS:
		printerr("[NetworkManager] Server full (%d/%d). Rejecting peer %d" % [connected_players.size(), MAX_PLAYERS, sender_id])
		if _peer != null:
			_peer.disconnect_peer(sender_id)
		return
	
	var sanitized_name: String = player_name.strip_edges()
	if sanitized_name.is_empty():
		sanitized_name = "Player_%d" % sender_id
	
	var initial_data: Dictionary = {
		"name": sanitized_name,
		"position": Vector3(0.0, 1.0, 0.0),
		"rotation_y": 0.0,
		"balance": 50000
	}
	connected_players[sender_id] = initial_data
	
	# Send complete current roster to newly joined client
	sync_player_roster.rpc_id(sender_id, connected_players)
	
	# Broadcast new player to all peers
	notify_player_joined.rpc(sender_id, sanitized_name, initial_data["position"], initial_data["rotation_y"], initial_data["balance"])
	player_joined.emit(sender_id, sanitized_name)

## Server distributes the roster of all connected players to a connecting client.
@rpc("authority", "call_remote", "reliable")
func sync_player_roster(roster: Dictionary) -> void:
	connected_players = roster.duplicate(true)
	var local_id: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 0
	
	for pid in connected_players.keys():
		var id_int: int = int(pid)
		var pdata: Dictionary = connected_players[pid]
		var pname: String = str(pdata.get("name", "Player"))
		var pos: Vector3 = pdata.get("position", Vector3.ZERO)
		var rot_y: float = float(pdata.get("rotation_y", 0.0))
		var bal: int = int(pdata.get("balance", 50000))
		
		if id_int != local_id:
			spawn_remote_player(id_int, pname, pos, rot_y, bal)
			player_joined.emit(id_int, pname)
		else:
			# Sync local client wallet with authoritative balance
			var em := get_node_or_null("/root/EconomyManager")
			if em != null and em.has_method("set_balance"):
				em.call("set_balance", bal)
			balance_updated.emit(id_int, bal)

## Notifies all clients that a new player entered the city.
@rpc("authority", "call_remote", "reliable")
func notify_player_joined(peer_id: int, p_name: String, pos: Vector3, rot_y: float, balance: int) -> void:
	var local_id: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 0
	connected_players[peer_id] = {
		"name": p_name,
		"position": pos,
		"rotation_y": rot_y,
		"balance": balance
	}
	
	if peer_id != local_id:
		spawn_remote_player(peer_id, p_name, pos, rot_y, balance)
		player_joined.emit(peer_id, p_name)

## Notifies all clients that a player left the city.
@rpc("authority", "call_remote", "reliable")
func notify_player_left(peer_id: int) -> void:
	if connected_players.has(peer_id):
		connected_players.erase(peer_id)
	despawn_remote_player(peer_id)
	player_left.emit(peer_id)

## Client sends kinematic snapshot to server at 20 Hz.
@rpc("any_peer", "call_remote", "unreliable")
func sync_player_transform(pos: Vector3, rot_y: float) -> void:
	if not is_server:
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	
	if not connected_players.has(sender_id):
		return
	
	connected_players[sender_id]["position"] = pos
	connected_players[sender_id]["rotation_y"] = rot_y
	player_transform_updated.emit(sender_id, pos, rot_y)
	
	# Broadcast to all peers
	broadcast_player_transform.rpc(sender_id, pos, rot_y)

## Server broadcasts kinematic snapshot of a player to other clients.
@rpc("authority", "call_remote", "unreliable")
func broadcast_player_transform(peer_id: int, pos: Vector3, rot_y: float) -> void:
	var local_id: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 0
	if peer_id == local_id:
		return
	
	if connected_players.has(peer_id):
		connected_players[peer_id]["position"] = pos
		connected_players[peer_id]["rotation_y"] = rot_y
	
	if remote_players.has(peer_id):
		var puppet: CharacterBody3D = remote_players[peer_id]
		if is_instance_valid(puppet) and puppet.has_method("set_target_transform"):
			puppet.call("set_target_transform", pos, rot_y)
	
	player_transform_updated.emit(peer_id, pos, rot_y)

## Server-Authoritative Transaction Request:
## Zero-trust validation. Server checks current balance, rejects overdrafts, commits changes, and notifies client.
@rpc("any_peer", "call_remote", "reliable")
func request_transaction(amount: int, reason: String) -> void:
	if not is_server:
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	
	if not connected_players.has(sender_id):
		return
	
	var current_balance: int = int(connected_players[sender_id].get("balance", 0))
	
	# Normalize transaction delta:
	# - Negative amount: debit / spend (e.g. -3,000 MMK)
	# - Positive amount with purchase/spend reason: treated as debit / spend
	# - Positive amount with earnings reason: credit / add
	var is_debit: bool = amount < 0
	if amount > 0:
		var r_lower: String = reason.to_lower()
		if r_lower.contains("spend") or r_lower.contains("buy") or r_lower.contains("purchase") \
			or r_lower.contains("cost") or r_lower.contains("overdraft") or r_lower.contains("expensive") \
			or r_lower.contains("pay"):
			is_debit = true
	
	var delta: int = -abs(amount) if is_debit else abs(amount)
	
	# Validate balance against overdraft
	if current_balance + delta < 0:
		printerr("[NetworkManager] Overdraft rejected for peer %d: %d MMK for '%s' (Balance: %d MMK)" % [sender_id, amount, reason, current_balance])
		transaction_processed.emit(sender_id, amount, current_balance, reason, false)
		if sender_id != 1 and multiplayer.has_multiplayer_peer():
			notify_transaction_result.rpc_id(sender_id, sender_id, amount, current_balance, reason, false)
		return
	
	var new_balance: int = current_balance + delta
	connected_players[sender_id]["balance"] = new_balance
	
	print("[NetworkManager] Transaction approved for peer %d: %d MMK for '%s' (New Balance: %d MMK)" % [sender_id, delta, reason, new_balance])
	transaction_processed.emit(sender_id, amount, new_balance, reason, true)
	balance_updated.emit(sender_id, new_balance)
	
	# Notify the requesting client of authoritative transaction approval
	if sender_id != 1 and multiplayer.has_multiplayer_peer():
		notify_transaction_result.rpc_id(sender_id, sender_id, amount, new_balance, reason, true)

## Server sends transaction outcome and authoritative balance update to client.
@rpc("authority", "call_remote", "reliable")
func notify_transaction_result(peer_id: int, amount: int, new_balance: int, reason: String, success: bool) -> void:
	if connected_players.has(peer_id):
		connected_players[peer_id]["balance"] = new_balance
	
	var local_id: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 0
	if peer_id == local_id:
		var em := get_node_or_null("/root/EconomyManager")
		if em != null and em.has_method("set_balance") and success:
			em.call("set_balance", new_balance)
		balance_updated.emit(peer_id, new_balance)
	
	if remote_players.has(peer_id):
		var puppet: CharacterBody3D = remote_players[peer_id]
		if is_instance_valid(puppet) and puppet.has_method("set_player_balance"):
			puppet.call("set_player_balance", new_balance)
	
	transaction_processed.emit(peer_id, amount, new_balance, reason, success)

## Sends a chat message to all players.
@rpc("any_peer", "call_local", "reliable")
func send_chat(sender_name: String, message: String) -> void:
	var clean_name: String = sender_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "Anonymous"
	var clean_msg: String = message.strip_edges()
	if clean_msg.length() > 250:
		clean_msg = clean_msg.substr(0, 250)
	
	chat_received.emit(clean_name, clean_msg)

# ==============================================================================
# PUPPET MANAGEMENT & LOCAL TICK
# ==============================================================================

func _sync_local_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null and is_instance_valid(player) and player.is_inside_tree():
		sync_player_transform.rpc_id(1, player.global_position, player.rotation.y)

## Spawns a RemotePlayer puppet for a peer in the city.
func spawn_remote_player(peer_id: int, p_name: String, pos: Vector3, rot_y: float, bal: int) -> CharacterBody3D:
	_ensure_remote_container()
	
	if remote_players.has(peer_id) and is_instance_valid(remote_players[peer_id]):
		var existing: CharacterBody3D = remote_players[peer_id]
		if existing.has_method("set_player_name"):
			existing.call("set_player_name", p_name)
		if existing.has_method("set_player_balance"):
			existing.call("set_player_balance", bal)
		if existing.has_method("set_target_transform"):
			existing.call("set_target_transform", pos, rot_y)
		return existing
	
	if _remote_player_scene == null:
		_remote_player_scene = load("res://scenes/player/remote_player.tscn")
	
	if _remote_player_scene == null:
		printerr("[NetworkManager] Failed to load remote_player.tscn")
		return null
	
	var puppet: CharacterBody3D = _remote_player_scene.instantiate() as CharacterBody3D
	puppet.name = "RemotePlayer_%d" % peer_id
	if puppet.has_method("set_player_name"):
		puppet.call("set_player_name", p_name)
	if puppet.has_method("set_player_balance"):
		puppet.call("set_player_balance", bal)
	if remote_players_container.is_inside_tree():
		puppet.global_position = pos
	else:
		puppet.position = pos
	puppet.rotation.y = rot_y
	if puppet.has_method("set_target_transform"):
		puppet.call("set_target_transform", pos, rot_y)
	
	remote_players_container.add_child(puppet)
	remote_players[peer_id] = puppet
	return puppet

## Despawns a peer's puppet upon departure.
func despawn_remote_player(peer_id: int) -> void:
	if remote_players.has(peer_id):
		var puppet: Node = remote_players[peer_id]
		if is_instance_valid(puppet):
			puppet.queue_free()
		remote_players.erase(peer_id)

## Clears all remote player instances.
func clear_all_remote_players() -> void:
	for pid in remote_players.keys():
		var puppet: Node = remote_players[pid]
		if is_instance_valid(puppet):
			puppet.queue_free()
	remote_players.clear()

## Helper method to retrieve connected player count.
func get_player_count() -> int:
	return connected_players.size()

## Helper method to retrieve player record by peer ID.
func get_player_data(peer_id: int) -> Dictionary:
	return connected_players.get(peer_id, {})
