extends CharacterBody3D

@onready var player = get_node("../Player")
@onready var hit_detector = get_node("HitDetector")
var speed = 3.0
var target: Node3D
func _ready():
	hit_detector.body_entered.connect(_on_body_entered)
 
func _on_body_entered(body):
	if body.is_in_group("Player"):
		print("Player Loses!!!!")
		get_tree().reload_current_scene()

func _physics_process(_delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		move_and_slide()
