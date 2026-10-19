extends Area3D
class_name InteractableZone
## Reusable Area3D for interactable objects in the world

@export var prompt_text: String = "Interact"
@export var interaction_type: String = "generic" # 'food_stall', 'tea_shop', 'job_board', 'park_bench'

signal interacted

var _last_interaction_frame: int = -1

func _ready() -> void:
	# Layer 4 = Interactables, Layer 2 = Characters
	collision_layer = 4
	collision_mask = 2
	monitoring = true

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if has_node("/root/InteractionManager"):
		var im: Node = get_node("/root/InteractionManager")
		if im.has_signal("interaction_triggered"):
			im.interaction_triggered.connect(_on_interaction_triggered)

func _is_player(body: Node) -> bool:
	if body == null:
		return false
	if body.is_in_group("player"):
		return true
	if body.name == "Player" or body.name.begins_with("Player"):
		return true
	if body.has_method("is_player") and body.is_player():
		return true
	return false

func _on_body_entered(body: Node3D) -> void:
	if _is_player(body):
		if has_node("/root/InteractionManager"):
			var im: Node = get_node("/root/InteractionManager")
			if im.has_method("register_interactable"):
				im.register_interactable(self, prompt_text)
			if im.has_method("set_nearest_interactable"):
				im.set_nearest_interactable(self, prompt_text)

func _on_body_exited(body: Node3D) -> void:
	if _is_player(body):
		if has_node("/root/InteractionManager"):
			var im: Node = get_node("/root/InteractionManager")
			if im.has_method("unregister_interactable"):
				im.unregister_interactable(self)
			if im.has_method("clear_interactable"):
				im.clear_interactable()

func _on_interaction_triggered(node: Node) -> void:
	if node == self:
		interact()

func interact() -> void:
	var current_frame: int = Engine.get_process_frames()
	if current_frame == _last_interaction_frame:
		return
	_last_interaction_frame = current_frame
	interacted.emit()
