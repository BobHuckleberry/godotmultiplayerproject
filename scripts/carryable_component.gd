extends Node
class_name CarryableComponent

@export var weight_kg: float = 5.0        # weight of the object

var currentInteractor: Node3D
#TODO: three interact funcs, start and stop grab
func interact(interactor: Node) -> void:
	print("Started carrying:", get_parent().name, "by", interactor.name)
	currentInteractor = interactor
