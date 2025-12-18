extends RayCast3D
class_name InteractorComponent

@export var player: Node3D
var current_target: InteractableComponent = null
var active_interaction_target: InteractableComponent = null

func _physics_process(_delta: float) -> void:
	force_raycast_update()
	current_target = null

	if not is_colliding():
		return

	var node := get_collider() as Node

	# walk up parents and also check their children
	while node:
		if node is InteractableComponent:
			current_target = node
			return

		for child in node.get_children():
			if child is InteractableComponent:
				current_target = child
				return
		node = node.get_parent()



func try_interact() -> void:
	start_interact()


func start_interact(target: InteractableComponent = null) -> void:
	var chosen := target if target != null else current_target
	if chosen:
		active_interaction_target = chosen
		chosen.start_interact(self)


func end_interact() -> void:
	if active_interaction_target and is_instance_valid(active_interaction_target):
		active_interaction_target.end_interact(self)
	active_interaction_target = null
