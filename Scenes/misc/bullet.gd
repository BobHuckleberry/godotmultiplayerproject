extends Area3D
class_name Bullet

@export var speed: float = 1.0
@export var lifetime: float = 3.0
@export var impact_impulse: float = 2.5
@export var min_effective_weight_kg: float = 0.1

var direction: Vector3 = Vector3.FORWARD
var _age: float = 0.0
var _has_hit: bool = false


func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _has_hit:
		return
	global_position += direction.normalized() * speed * delta

	_age += delta
	if _age >= lifetime:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if _has_hit:
		return
	_has_hit = true

	var rigid_body := body as RigidBody3D
	if rigid_body:
		var weight_kg := _get_effective_weight_kg(rigid_body)
		var impulse_scale := rigid_body.mass / weight_kg
		var impulse := direction.normalized() * impact_impulse * impulse_scale
		rigid_body.apply_impulse(impulse)

	queue_free()


func _get_effective_weight_kg(body: RigidBody3D) -> float:
	for child in body.get_children():
		if child is CarryableComponent:
			var carryable := child as CarryableComponent
			return max(carryable.weight_kg, min_effective_weight_kg)

	return max(body.mass, min_effective_weight_kg)
