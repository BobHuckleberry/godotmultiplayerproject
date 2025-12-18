extends Area3D
class_name Bullet

@export var speed: float = 1.0
@export var lifetime: float = 3.0
@export var impact_impulse: float = 25.0
@export var min_effective_weight_kg: float = 0.1
@export var hit_collision_mask: int = 0xFFFFFFFF
@export var debug_hits: bool = false

var direction: Vector3 = Vector3.FORWARD
var _age: float = 0.0
var _has_hit: bool = false
var _exclude_rids: Array[RID] = []


func _ready() -> void:
	# Hit detection is handled via raycasts in _physics_process.
	monitoring = false


func _physics_process(delta: float) -> void:
	if _has_hit:
		return

	var from_pos := global_position
	var travel := direction.normalized() * speed * delta
	var to_pos := from_pos + travel

	var hit := _raycast_hit(from_pos, to_pos)
	if not hit.is_empty():
		_handle_hit(hit.get("collider"), hit.get("position", from_pos))
		return

	global_position = to_pos

	_age += delta
	if _age >= lifetime:
		queue_free()


func ignore_collision_with(node: Node) -> void:
	var collision_object := node as CollisionObject3D
	if collision_object == null:
		return

	var rid := collision_object.get_rid()
	if not _exclude_rids.has(rid):
		_exclude_rids.append(rid)


func _raycast_hit(from_pos: Vector3, to_pos: Vector3) -> Dictionary:
	var world := get_world_3d()
	if world == null:
		return {}

	var query := PhysicsRayQueryParameters3D.new()
	query.from = from_pos
	query.to = to_pos
	query.exclude = _exclude_rids
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.hit_from_inside = true
	query.collision_mask = hit_collision_mask if hit_collision_mask != 0 else collision_mask

	return world.direct_space_state.intersect_ray(query)


func _handle_hit(collider: Object, hit_position: Vector3) -> void:
	if _has_hit:
		return
	_has_hit = true

	var rigid_body := collider as RigidBody3D
	if rigid_body:
		var weight_kg := _get_effective_weight_kg(rigid_body)
		var impulse_scale := rigid_body.mass / weight_kg
		var impulse := direction.normalized() * impact_impulse * impulse_scale
		rigid_body.sleeping = false
		rigid_body.apply_impulse(impulse)

		if debug_hits:
			print(
				"[Bullet] hit RigidBody3D:", rigid_body.name,
				" mass:", rigid_body.mass,
				" weight_kg:", weight_kg,
				" impulse:", impulse,
				" at:", hit_position
			)
	elif debug_hits:
		var collider_name: String
		if collider is Node:
			collider_name = str((collider as Node).name)
		else:
			collider_name = str(collider)
		print("[Bullet] hit non-rigidbody:", collider_name, " at:", hit_position)

	queue_free()


func _get_effective_weight_kg(body: RigidBody3D) -> float:
	var carryable := _find_carryable_recursive(body)
	if carryable:
		return max(carryable.weight_kg, min_effective_weight_kg)

	return max(body.mass, min_effective_weight_kg)


func _find_carryable_recursive(node: Node) -> CarryableComponent:
	for child in node.get_children():
		if child is CarryableComponent:
			return child as CarryableComponent
		var nested := _find_carryable_recursive(child)
		if nested:
			return nested
	return null
