extends Node
class_name CarryableComponent

@export var weight_kg: float = 5.0        # weight of the object

func interact(interactor: Node) -> void:
	print("Carrying:", get_parent().name, "by", interactor.name)
