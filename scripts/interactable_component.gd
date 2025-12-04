extends Node
class_name InteractableComponent

@export var interaction_owner: Node = null  # usually the Oven script

func interact(interactor: Node) -> void:
	if interaction_owner and interaction_owner.has_method("on_interacted"):
		interaction_owner.on_interacted(interactor)
	else:
		print("Interacted with:", name)
