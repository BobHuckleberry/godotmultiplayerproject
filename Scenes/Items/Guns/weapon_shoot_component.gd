extends Node3D
class_name WeaponShootComponent

signal shoot(interactor: Node)

@export var ammo_component_path: NodePath

var carryable: CarryableComponent
var ammo_component: WeaponAmmoComponent
var weapon_body: RigidBody3D

var is_interacting: bool = false
var active_interactor: Node = null


func _ready() -> void:
	print("[WeaponShootComponent] _ready: initializing for", get_parent())
	weapon_body = get_parent() as RigidBody3D
	if weapon_body == null:
		push_error("WeaponShootComponent expects its parent to be a RigidBody3D.")
		print("[WeaponShootComponent] ERROR: parent is not RigidBody3D")

	carryable = _find_carryable()
	print("[WeaponShootComponent] carryable found:", carryable)
	ammo_component = _resolve_ammo_component()
	print("[WeaponShootComponent] ammo component resolved:", ammo_component)


func on_interact_start(interactor: Node) -> void:
	print("[WeaponShootComponent] on_interact_start by", interactor)
	is_interacting = true
	active_interactor = interactor


func on_interact_end(_interactor: Node) -> void:
	print("[WeaponShootComponent] on_interact_end by", _interactor)
	is_interacting = false
	active_interactor = null


func try_shoot(requester: Node = null) -> bool:
	print("[WeaponShootComponent] try_shoot requested by", requester)
	if not _can_shoot():
		print("[WeaponShootComponent] try_shoot blocked: cannot shoot")
		return false

	if ammo_component and not ammo_component.consume_rounds(1):
		print("[WeaponShootComponent] try_shoot blocked: ammo consume failed")
		return false

	var shooter := requester if requester != null else active_interactor
	print("[WeaponShootComponent] shooting; emitter interactor:", shooter)
	emit_signal("shoot", shooter)
	return true


func _can_shoot() -> bool:
	print("[WeaponShootComponent] _can_shoot check")
	var held := _is_currently_held()
	if not held:
		print("[WeaponShootComponent] _can_shoot: not currently held")
		return false

	var interacting := is_interacting or held
	if not interacting:
		print("[WeaponShootComponent] _can_shoot: not interacting")
		return false

	if ammo_component == null:
		print("[WeaponShootComponent] _can_shoot: no ammo component")
		return false

	var has_ammo := ammo_component.has_rounds(1)
	print("[WeaponShootComponent] _can_shoot: ammo available?", has_ammo)
	return ammo_component.has_rounds(1)


func _is_currently_held() -> bool:
	print("[WeaponShootComponent] _is_currently_held check")
	if carryable == null:
		print("[WeaponShootComponent] _is_currently_held: no carryable")
		return false

	var grabber_candidate := carryable.currentInteractor
	if grabber_candidate == null or not (grabber_candidate is GrabComponent):
		print("[WeaponShootComponent] _is_currently_held: no grabber or not GrabComponent")
		return false

	var grab_component := grabber_candidate as GrabComponent
	var is_held := grab_component.grabbed_body == weapon_body
	print("[WeaponShootComponent] _is_currently_held:", is_held)
	return grab_component.grabbed_body == weapon_body


func _find_carryable() -> CarryableComponent:
	print("[WeaponShootComponent] _find_carryable search")
	var parent := get_parent()
	if parent == null:
		print("[WeaponShootComponent] _find_carryable: no parent")
		return null

	for child in parent.get_children():
		if child is CarryableComponent:
			print("[WeaponShootComponent] _find_carryable: found", child)
			return child
	print("[WeaponShootComponent] _find_carryable: none found")
	return null


func _resolve_ammo_component() -> WeaponAmmoComponent:
	print("[WeaponShootComponent] _resolve_ammo_component")
	if ammo_component_path != NodePath():
		var explicit := get_node_or_null(ammo_component_path) as WeaponAmmoComponent
		if explicit:
			print("[WeaponShootComponent] _resolve_ammo_component: found via path", ammo_component_path)
			return explicit

	var parent := get_parent()
	if parent:
		print("[WeaponShootComponent] _resolve_ammo_component: checking sibling 'WeaponAmmoComponent'")
		return parent.get_node_or_null("WeaponAmmoComponent") as WeaponAmmoComponent

	print("[WeaponShootComponent] _resolve_ammo_component: no ammo component found")
	return null
