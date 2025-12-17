extends Node3D
class_name WeaponAdjustmentComponent

var weapon_body: RigidBody3D
var carryable: CarryableComponent


func _ready() -> void:
	weapon_body = get_parent() as RigidBody3D
	if weapon_body == null:
		push_error("WeaponAdjustmentComponent expects its parent to be a RigidBody3D.")
	carryable = _find_carryable()


func _physics_process(_delta: float) -> void:
	if weapon_body == null:
		return

	var grabber := _get_active_grabber()
	if grabber == null:
		return

	var camera := _find_camera(grabber)
	if camera == null:
		return

	# Keep the weapon's +Z aligned with the player's view while it is grabbed.
	var updated_transform := weapon_body.global_transform
	var camera_basis := camera.global_transform.basis.orthonormalized()
	var forward := -camera_basis.z.normalized() # camera forward is -Z; weapon forward should be +Z
	var up := camera_basis.y.normalized()
	var right := up.cross(forward).normalized()
	up = forward.cross(right).normalized()
	updated_transform.basis = Basis(right, up, forward)
	weapon_body.global_transform = updated_transform


func _find_carryable() -> CarryableComponent:
	var parent := get_parent()
	if parent == null:
		return null

	for child in parent.get_children():
		if child is CarryableComponent:
			return child
	return null


func _get_active_grabber() -> GrabComponent:
	if carryable == null:
		carryable = _find_carryable()
	if carryable == null:
		return null

	var grabber_candidate := carryable.currentInteractor
	if grabber_candidate == null or not (grabber_candidate is GrabComponent):
		return null

	var grabber := grabber_candidate as GrabComponent
	if grabber.grabbed_body != weapon_body:
		return null

	return grabber


func _find_camera(start: Node) -> Camera3D:
	var current: Node = start
	while current:
		if current is Camera3D:
			return current

		for child in current.get_children():
			if child is Camera3D:
				return child

		current = current.get_parent()

	return null
