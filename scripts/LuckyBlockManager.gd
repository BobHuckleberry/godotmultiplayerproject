extends Node3D
class_name LuckyBlockManager

@export var weapons: Array[PackedScene] = []

func roll_lucky_block() -> PackedScene:
	if weapons.is_empty():
		return null
	return weapons.pick_random()
