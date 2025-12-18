extends Area3D
class_name Bullet

@export var speed: float = 1.0
@export var lifetime: float = 3.0

var direction: Vector3 = Vector3.FORWARD
var _age: float = 0.0


func _physics_process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta

	_age += delta
	if _age >= lifetime:
		queue_free()
