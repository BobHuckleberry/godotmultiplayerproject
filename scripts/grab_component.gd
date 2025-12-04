extends RayCast3D
class_name GrabComponent

@export_category("Grab Handle")
@export var grab_handle_scene: PackedScene   # assign GrabHandle.tscn


var current_target: CarryableComponent = null
var grabbed_body: RigidBody3D = null

var grab_handle: RigidBody3D = null          # instance of GrabHandle.tscn
var joint: Generic6DOFJoint3D = null         # the actual joint

var grab_local_offset: Vector3 = Vector3.ZERO

var grab_distance: float = 3.0
var min_grab_distance: float = 1.0
var max_grab_distance: float = 6.0

# For carrying momentum / throw
var last_handle_position: Vector3 = Vector3.ZERO
var handle_velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	enabled = true


func _physics_process(delta: float) -> void:
	_update_current_target()
	_update_grabbed_body(delta)


func _update_current_target() -> void:
	current_target = null

	if not is_colliding():
		return

	var collider: Node = get_collider()
	var found: CarryableComponent = _find_carryable_in_parents(collider)
	if found == null:
		found = _find_carryable_in_children(collider)

	current_target = found


func try_interact() -> void:
	if grabbed_body:
		_release_grab()
		return

	if current_target:
		_start_grab(current_target)


func _start_grab(target: CarryableComponent) -> void:
	var body := target.get_parent() as RigidBody3D
	if body == null:
		push_warning("CarryableComponent has no RigidBody3D parent.")
		return

	if grab_handle_scene == null:
		push_error("grab_handle_scene is not assigned on InteractorComponent.")
		return

	grabbed_body = body

	# Optional: map weight to mass
	grabbed_body.mass = max(target.weight_kg, 0.1)

	# Spawn the grab handle
	grab_handle = grab_handle_scene.instantiate() as RigidBody3D
	get_tree().current_scene.add_child(grab_handle)
	
	#fixes the sag for some reason
	grab_handle.gravity_scale = 0.0
	grab_handle.linear_damp = 10.0
	grab_handle.angular_damp = 10.0
	# Position handle at hit point
	var hit_point: Vector3 = get_collision_point()
	grab_local_offset = grabbed_body.to_local(hit_point)
	grab_handle.global_position = hit_point
	last_handle_position = hit_point
	handle_velocity = Vector3.ZERO

	# Get joint on the handle
	joint = grab_handle.get_node("Joint") as Generic6DOFJoint3D
	if joint == null:
		push_error("GrabHandle scene is missing a child named 'Joint' of type Generic6DOFJoint3D.")
		return

	# Connect joint
	joint.node_a = grab_handle.get_path()
	joint.node_b = grabbed_body.get_path()

	_configure_joint(target.weight_kg)
	target.interact(self)


func _configure_joint(weight: float) -> void:
	if joint == null:
		return

	# Heavier object = weaker springs, more damping
	var t: float = clamp(weight / 50.0, 0.0, 1.0)
	var strength: float = lerp(40.0, 10.0, t)   # light -> stiff, heavy -> softer
	var damping: float = lerp(0.5, 5.0, t)      # light -> low damping, heavy -> more damping

	# Enable linear limits so springs have something to work against
	for axis in ["x", "y", "z"]:
		joint.set("linear_limit_%s/enabled" % axis, true)
		# Small range around the handle (acts like soft attachment)
		joint.set("linear_limit_%s/lower_distance" % axis, -0.05)
		joint.set("linear_limit_%s/upper_distance" % axis,  0.05)
		joint.set("linear_limit_%s/softness" % axis, 0.7)
		joint.set("linear_limit_%s/damping" % axis, 1.0)

		# Springs (from the docs: "linear_spring_x/stiffness", etc.)
		joint.set("linear_spring_%s/enabled" % axis, true)
		joint.set("linear_spring_%s/stiffness" % axis, strength)
		joint.set("linear_spring_%s/damping" % axis, damping)
		joint.set("linear_spring_%s/equilibrium_point" % axis, 0.0)

	# You *can* also add angular springs here later if rotation is too floppy:
	# joint.set("angular_spring_x/enabled", true)
	# ...


func _update_grabbed_body(delta: float) -> void:
	if grabbed_body == null or grab_handle == null:
		return

	grab_distance = clamp(grab_distance, min_grab_distance, max_grab_distance)

	# Target position in front of the raycast
	var target_pos: Vector3 = global_position + -global_basis.z * grab_distance

	#change velocity before moving it
	handle_velocity = (target_pos - last_handle_position) / max(delta, 0.0001)
	last_handle_position = target_pos

	# Move the kinematic handle; the joint + springs do the rest
	grab_handle.global_position = target_pos



func _release_grab() -> void:
	if grabbed_body != null:
		# Apply the handle's motion as throw velocity when letting go
		grabbed_body.linear_velocity += handle_velocity

	if grab_handle:
		grab_handle.queue_free()

	grab_handle = null
	joint = null
	grabbed_body = null
	handle_velocity = Vector3.ZERO


# Search funcs
func _find_carryable_in_parents(node: Node) -> CarryableComponent:
	var current := node
	while current:
		if current is CarryableComponent:
			return current
		current = current.get_parent()
	return null


func _find_carryable_in_children(node: Node) -> CarryableComponent:
	for child in node.get_children():
		if child is CarryableComponent:
			return child
		var nested = _find_carryable_in_children(child)
		if nested:
			return nested
	return null
