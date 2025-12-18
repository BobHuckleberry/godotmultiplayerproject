extends RigidBody3D
class_name Pistol

@export var bullet_scene: PackedScene = preload("res://Scenes/misc/bullet.tscn")

@onready var gun_tip: Node3D = $"GunTip (Marker)"
@onready var shoot_component: WeaponShootComponent = $WeaponShootComponent


func _ready() -> void:
	print("[Pistol] _ready: setting up shoot listener")
	if shoot_component:
		shoot_component.connect("shoot", Callable(self, "_on_shoot"))
		print("[Pistol] connected to WeaponShootComponent shoot signal")
	else:
		push_error("Pistol is missing WeaponShootComponent.")
		print("[Pistol] ERROR: missing WeaponShootComponent")


func _on_shoot(interactor: Node) -> void:
	print("[Pistol] shoot signal received, spawning bullet")
	_spawn_bullet(interactor)
	print("[Pistol] Bullet Spawned")


func _spawn_bullet(interactor: Node = null) -> void:
	if bullet_scene == null:
		push_error("Pistol bullet_scene is not assigned.")
		return
	if gun_tip == null:
		push_error("Pistol cannot find GunTip.")
		return

	var bullet := bullet_scene.instantiate() as Node3D
	if bullet == null:
		push_error("Failed to instance bullet scene.")
		return

	var world := get_tree().current_scene
	if world == null:
		push_error("No current scene to spawn bullet into.")
		return

	world.add_child(bullet)
	bullet.global_transform = gun_tip.global_transform

	var forward := gun_tip.global_transform.basis.z.normalized()
	if bullet is Bullet:
		var bullet_instance := bullet as Bullet
		bullet_instance.direction = forward
		bullet_instance.ignore_collision_with(self)
		var shooter_body := _find_collision_object(interactor)
		if shooter_body:
			bullet_instance.ignore_collision_with(shooter_body)
	elif bullet.has_method("set_direction"):
		bullet.call("set_direction", forward)


func _find_collision_object(start: Node) -> CollisionObject3D:
	var current: Node = start
	while current:
		if current is CollisionObject3D:
			return current as CollisionObject3D
		current = current.get_parent()
	return null
