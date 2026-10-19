class_name MobileKeypad
extends Control

## On-screen virtual keypad & touch controls for mobile players.
##
## Emits native Godot Input actions (move_forward, move_backward, move_left,
## move_right, sprint, jump, interact, enter_vehicle, toggle_phone, toggle_inventory)
## enabling seamless mobile gameplay.

@export var auto_show_on_touch: bool = true

func _ready() -> void:
	# Check if running on mobile OS or touch screen
	var os_name := OS.get_name()
	if os_name == "Android" or os_name == "iOS" or DisplayServer.is_touchscreen_available():
		visible = true
	else:
		# On desktop browsers, default to visible with toggle option
		visible = true

	_bind_button("DPad/BtnUp", "move_forward")
	_bind_button("DPad/BtnDown", "move_backward")
	_bind_button("DPad/BtnLeft", "move_left")
	_bind_button("DPad/BtnRight", "move_right")
	_bind_button("DPad/BtnSprint", "sprint")

	_bind_button("ActionGroup/BtnJump", "jump")
	_bind_button("ActionGroup/BtnRide", "enter_vehicle")
	_bind_button("ActionGroup/BtnPhone", "toggle_phone")
	_bind_button("ActionGroup/BtnInventory", "toggle_inventory")

	var btn_interact := get_node_or_null("ActionGroup/BtnInteract") as Button
	if btn_interact:
		btn_interact.pressed.connect(_on_interact_pressed)

	var btn_cam_l := get_node_or_null("ActionGroup/BtnCamLeft") as Button
	if btn_cam_l:
		btn_cam_l.pressed.connect(func(): _rotate_camera(-deg_to_rad(45.0)))

	var btn_cam_r := get_node_or_null("ActionGroup/BtnCamRight") as Button
	if btn_cam_r:
		btn_cam_r.pressed.connect(func(): _rotate_camera(deg_to_rad(45.0)))

func _bind_button(node_path: String, action_name: String) -> void:
	var btn := get_node_or_null(node_path) as Button
	if not btn:
		return

	btn.button_down.connect(func():
		Input.action_press(action_name)
	)
	btn.button_up.connect(func():
		Input.action_release(action_name)
	)

func _on_interact_pressed() -> void:
	var im: Node = get_node_or_null("/root/InteractionManager")
	if im and im.has_method("trigger_interaction"):
		im.call("trigger_interaction")
	else:
		Input.action_press("interact")
		Input.action_release("interact")

func _rotate_camera(yaw_delta: float) -> void:
	var p_nodes := get_tree().get_nodes_in_group("player")
	if not p_nodes.is_empty():
		var player := p_nodes[0]
		if "_target_yaw" in player:
			player._target_yaw += yaw_delta

func toggle_keypad() -> bool:
	visible = not visible
	return visible
