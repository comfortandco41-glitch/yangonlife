class_name ServerMain
extends Node
## Dedicated Headless Server for Yangon Life (ရန်ကုန် ဘဝ).
##
## Manages headless city instance, authoritative client sessions,
## zero-trust economy validation, and city simulation ticks.

const DEFAULT_SERVER_PORT: int = 8910
const CITY_TICK_INTERVAL: float = 1.0 # 1 real second per simulation tick
const HEARTBEAT_INTERVAL: float = 15.0 # Status log interval in seconds

var server_port: int = DEFAULT_SERVER_PORT
var is_running: bool = false
var peer_count: int = 0

var city_tick_timer: float = 0.0
var heartbeat_timer: float = 0.0
var total_city_ticks: int = 0
var total_transactions: int = 0
var total_transaction_volume: int = 0
var rejected_transactions: int = 0

func _ready() -> void:
	print("==================================================")
	print("  YANGON LIFE (ရန်ကုန် ဘဝ) — DEDICATED HEADLESS SERVER")
	print("==================================================")
	
	_parse_command_line_args()
	_connect_network_signals()
	
	# Start server via NetworkManager singleton
	var nm: Node = get_node_or_null("/root/NetworkManager")
	if nm != null and nm.has_method("start_server"):
		nm.call("start_server", server_port)
	else:
		printerr("[ServerMain] NetworkManager autoload not found! Cannot start server.")

func _parse_command_line_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		args = OS.get_cmdline_args()
	
	for i in range(args.size()):
		var arg: String = args[i]
		if arg == "--port" and i + 1 < args.size():
			server_port = args[i + 1].to_int()
		elif arg.begins_with("--port="):
			server_port = arg.substr(7).to_int()

func _connect_network_signals() -> void:
	var nm: Node = get_node_or_null("/root/NetworkManager")
	if nm == null:
		return
	
	if nm.has_signal("server_started") and not nm.server_started.is_connected(_on_server_started):
		nm.server_started.connect(_on_server_started)
	if nm.has_signal("server_stopped") and not nm.server_stopped.is_connected(_on_server_stopped):
		nm.server_stopped.connect(_on_server_stopped)
	if nm.has_signal("player_joined") and not nm.player_joined.is_connected(_on_player_joined):
		nm.player_joined.connect(_on_player_joined)
	if nm.has_signal("player_left") and not nm.player_left.is_connected(_on_player_left):
		nm.player_left.connect(_on_player_left)
	if nm.has_signal("chat_received") and not nm.chat_received.is_connected(_on_chat_received):
		nm.chat_received.connect(_on_chat_received)
	if nm.has_signal("transaction_processed") and not nm.transaction_processed.is_connected(_on_transaction_processed):
		nm.transaction_processed.connect(_on_transaction_processed)

func _physics_process(delta: float) -> void:
	if not is_running:
		return
	
	city_tick_timer += delta
	if city_tick_timer >= CITY_TICK_INTERVAL:
		city_tick_timer -= CITY_TICK_INTERVAL
		_simulate_city_tick()
	
	heartbeat_timer += delta
	if heartbeat_timer >= HEARTBEAT_INTERVAL:
		heartbeat_timer -= HEARTBEAT_INTERVAL
		_log_server_heartbeat()

## Headless city simulation tick: advances server time, economy pulse, and jobs.
func _simulate_city_tick() -> void:
	total_city_ticks += 1
	
	# Advance authoritative world time if TimeManager is present
	var tm: Node = get_node_or_null("/root/TimeManager")
	if tm != null and tm.has_method("advance_time"):
		tm.call("advance_time", 1)

func _log_server_heartbeat() -> void:
	var mem_mb: float = float(OS.get_static_memory_usage()) / (1024.0 * 1024.0)
	print("[SERVER HEARTBEAT] Ticks: %d | Peers: %d/%d | Tx: %d (Vol: %d MMK, Rej: %d) | RAM: %0.1f MB" % [
		total_city_ticks,
		peer_count,
		NetworkManager.MAX_PLAYERS,
		total_transactions,
		total_transaction_volume,
		rejected_transactions,
		mem_mb
	])

# ==============================================================================
# NETWORK EVENT HANDLERS
# ==============================================================================

func _on_server_started(port: int) -> void:
	is_running = true
	server_port = port
	print("[ServerMain] Headless city instance online at ws://0.0.0.0:%d" % port)

func _on_server_stopped() -> void:
	is_running = false
	print("[ServerMain] Headless server stopped.")

func _on_player_joined(peer_id: int, p_name: String) -> void:
	var nm: Node = get_node_or_null("/root/NetworkManager")
	if nm != null and "connected_players" in nm:
		peer_count = nm.connected_players.size()
	else:
		peer_count += 1
	print("[ServerMain] Player connected: '%s' (Peer ID: %d). Total online: %d/%d" % [
		p_name, peer_id, peer_count, NetworkManager.MAX_PLAYERS
	])

func _on_player_left(peer_id: int) -> void:
	var nm: Node = get_node_or_null("/root/NetworkManager")
	if nm != null and "connected_players" in nm:
		peer_count = nm.connected_players.size()
	else:
		peer_count = maxi(0, peer_count - 1)
	print("[ServerMain] Player disconnected: Peer ID %d. Total online: %d/%d" % [
		peer_id, peer_count, NetworkManager.MAX_PLAYERS
	])

func _on_chat_received(sender_name: String, message: String) -> void:
	print("[SERVER CHAT] <%s>: %s" % [sender_name, message])

func _on_transaction_processed(peer_id: int, amount: int, new_balance: int, reason: String, success: bool) -> void:
	if success:
		total_transactions += 1
		total_transaction_volume += abs(amount)
		print("[SERVER ECONOMY APPROVED] Peer %d | Reason: '%s' | Amount: %d MMK | New Balance: %d MMK" % [
			peer_id, reason, amount, new_balance
		])
	else:
		rejected_transactions += 1
		print("[SERVER ECONOMY REJECTED] Peer %d attempted overdraft: %d MMK for '%s' (Current Balance: %d MMK)" % [
			peer_id, amount, reason, new_balance
		])

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if is_inside_tree():
			print("[ServerMain] Shutting down headless server...")
			var nm: Node = get_node_or_null("/root/NetworkManager")
			if nm != null and nm.has_method("disconnect_network"):
				nm.call("disconnect_network")
