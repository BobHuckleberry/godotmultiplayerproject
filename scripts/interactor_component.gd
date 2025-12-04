extends RayCast3D
class_name InteractorComponent

@export var player: Node3D
var current_target: InteractableComponent = null

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
	print("trying")
	if current_target:
		print(current_target)
		current_target.interact(self)
