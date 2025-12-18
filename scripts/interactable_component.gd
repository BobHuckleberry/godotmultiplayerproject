extends Node
class_name InteractableComponent

@export var interaction_owner: Node = null

func interact(interactor: Node) -> void:
	if interaction_owner and interaction_owner.has_method("on_interacted"):
		interaction_owner.on_interacted(interactor)
	else:
		print("Interacted with:", name)


func start_interact(interactor: Node) -> void:
	if interaction_owner and interaction_owner.has_method("on_interact_start"):
		interaction_owner.on_interact_start(interactor)
	elif interaction_owner and interaction_owner.has_method("on_interacted"):
		# Fallback to the original single-shot interaction.
		interaction_owner.on_interacted(interactor)
	else:
		print("Started interacting with:", name)


func end_interact(interactor: Node) -> void:
	if interaction_owner and interaction_owner.has_method("on_interact_end"):
		interaction_owner.on_interact_end(interactor)
	else:
		print("Stopped interacting with:", name)
