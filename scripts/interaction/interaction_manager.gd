extends Node
## Interaction Manager — Proximity-based interaction system
##
## Tracks overlapping interactable areas (Physics Layer 4),
## identifies the nearest interactable relative to player position,
## displays interaction prompts, and dispatches interaction trigger events.

signal interactable_entered(node: Node, prompt: String)
signal interactable_exited
signal interaction_triggered(node: Node)

var current_interactable: Node = null
var interaction_prompt: String = ""

# Map of active overlapping Area3D -> prompt string
var _registered_areas: Dictionary = {}

func _process(_delta: float) -> void:
	if not _registered_areas.is_empty():
		_update_nearest_interactable()
	elif current_interactable != null and not is_instance_valid(current_interactable):
		clear_interactable()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		trigger_interaction()

## Registers an interactable Area3D currently in proximity
func register_interactable(area: Area3D, prompt: String) -> void:
	if not area:
		return
	_registered_areas[area] = prompt
	_update_nearest_interactable()

## Unregisters an interactable Area3D when out of proximity
func unregister_interactable(area: Area3D) -> void:
	if area in _registered_areas:
		_registered_areas.erase(area)
	if current_interactable == area:
		_update_nearest_interactable()

## Explicitly sets current nearest interactable target and prompt
func set_nearest_interactable(node: Node, prompt: String) -> void:
	if current_interactable == node and interaction_prompt == prompt:
		return
	current_interactable = node
	interaction_prompt = prompt
	interactable_entered.emit(node, prompt)

## Clears current active interactable
func clear_interactable() -> void:
	if current_interactable != null or interaction_prompt != "":
		current_interactable = null
		interaction_prompt = ""
		interactable_exited.emit()

## Triggers interaction with the nearest interactable object (called on 'interact' key press)
func trigger_interaction() -> void:
	if current_interactable == null or not is_instance_valid(current_interactable):
		return

	interaction_triggered.emit(current_interactable)

	# Execute interact() method if implemented on the area or its parent
	if current_interactable.has_method("interact"):
		current_interactable.interact()
	elif current_interactable.get_parent() and current_interactable.get_parent().has_method("interact"):
		current_interactable.get_parent().interact()

## Checks if there is an active interactable ready for interaction
func has_interactable() -> bool:
	return current_interactable != null and is_instance_valid(current_interactable)

## Returns the current active interactable node
func get_current_interactable() -> Node:
	return current_interactable

## Returns the current interaction prompt string
func get_interaction_prompt() -> String:
	return interaction_prompt

func _update_nearest_interactable() -> void:
	# Prune any freed or invalid nodes
	var invalid_keys: Array[Area3D] = []
	for area: Area3D in _registered_areas:
		if not is_instance_valid(area) or not area.is_inside_tree():
			invalid_keys.append(area)
	for area in invalid_keys:
		_registered_areas.erase(area)

	if _registered_areas.is_empty():
		clear_interactable()
		return

	var player := _get_player_node()
	var nearest_area: Area3D = null
	var min_distance_sq: float = INF

	for area: Area3D in _registered_areas:
		if player != null:
			var dist_sq: float = player.global_position.distance_squared_to(area.global_position)
			if dist_sq < min_distance_sq:
				min_distance_sq = dist_sq
				nearest_area = area
		else:
			nearest_area = area
			break

	if nearest_area != null:
		set_nearest_interactable(nearest_area, _registered_areas[nearest_area])
	else:
		clear_interactable()

func _get_player_node() -> Node3D:
	var player_nodes := get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0 and player_nodes[0] is Node3D:
		return player_nodes[0] as Node3D
	return null
