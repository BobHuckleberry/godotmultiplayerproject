extends CharacterBody3D


# ========== PARAMETERS ==========
@export_category("Movement")
@export var BASE_SPEED: float = 5.0
@export var SPRINT_SPEED: float = 2.0
@export var JUMP_VELOCITY: float = 4.5
@export var ACCEL: float = 6.0
@export var DECEL: float = 10.0

@export_category("Mouse Controls")
@export var MOUSE_SENSITIVITY: float = 0.002
@export var MAX_PITCH: float = 1.2

#Multiplaction of player movement

#Normal height
@export_category("Crouch Controls")
@export var PLAYER_HEIGHT: float = 1.0
#Transform height of player from crouching
@export var CROUCH_HEIGHT: float = 0.7
#Crouch speed
@export var CROUCH_SPEED: float = 5.0
#Item interaction
@export_category("Item Controls")
@export var INTERACT_RANGE: float = 5.0
@export var ITEM_MOVE_SPEED: float = 0.15
@export var ITEM_MOVE_DISTANCE: float = 1.0

	# --- Camera Bob ---
@export_category("Camera Bob")
@export var bob_speed: float = 15.0
@export var bob_amount: float = 0.05   # vertical offset
var bob_time: float = 0.0

# --- Camera Sway ---
@export_category("Camera Sway")
@export var sway_amount := 0.03
@export var sway_smooth := 6.0
var sway_target := 0.0
var sway_current := 0.0


var _input_dir: Vector2 = Vector2.ZERO
var mouse_locked: bool = true

var wants_to_grab: bool = false

var wants_to_jump: bool = false
var wants_to_sprint: bool = false
var wants_to_crouch: bool = false
var wants_to_interact: bool = false


@onready var grab := $Head/GrabComponent
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interactor: InteractorComponent = $Head/InteractorComponent
@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer



#Locks player in on launch 
func _ready() -> void:
	if is_multiplayer_authority():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		camera.current = true
	else:
		camera.current = false

	
#Registers players mouse movement into camera rotation
func _input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return
	if event is InputEventMouseMotion:
		_handle_mouse_look(event as InputEventMouseMotion)

func _physics_process(delta: float) -> void:
	#Checks if on foot or driving and reads input
	if not is_multiplayer_authority():
		return

	_read_input()


	#These functions check for certain conditions and updates the player accordingly 
	_apply_gravity(delta)
	_apply_jump()
	_apply_movement(delta)
	_apply_camera_motion(delta)
	_apply_UI()
	#in built function that moves the body based on velocity
	move_and_slide()

# ---------- HELPER: MOUSE LOOK ----------
func _handle_mouse_look(mouse_event: InputEventMouseMotion) -> void:
	#left right
	rotate_y(-mouse_event.relative.x * MOUSE_SENSITIVITY)
	#up down
	head.rotate_x(-mouse_event.relative.y * MOUSE_SENSITIVITY)
	#clamp
	head.rotation.x = clamp(head.rotation.x, -MAX_PITCH, MAX_PITCH)

# ------- HELPER: READ INPUT STATE -------
# Maps player inputs to different vars
func _read_input() -> void:
	#get a 2D vector of players WASD movement
	_input_dir = Input.get_vector("Move_Left", "Move_Right", "Move_Up", "Move_Down")
	#Records if player wants to jump
	if Input.is_action_just_pressed("Jump"):
		wants_to_jump = true
	#For escaping the program
	if Input.is_action_just_pressed("Escape"):
		mouse_locked = !mouse_locked
	#Sprint press and release
	if Input.is_action_just_pressed("Sprint"):
		wants_to_sprint = true
	if Input.is_action_just_released("Sprint"):
		wants_to_sprint = false
	#Crouching
	if Input.is_action_just_pressed("Crouch"):
		wants_to_crouch = !wants_to_crouch
	if Input.is_action_just_pressed("Grab"):
		wants_to_grab = true
		grab.try_interact()
	if Input.is_action_just_released("Grab"):
		wants_to_grab = false
		grab._release_grab()
	if Input.is_action_just_pressed("Interact"):
		interactor.try_interact()



# ------ HELPER: PHYSICS/MOVEMENT ------
#Applies gravity when player is not on ground
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

#Player must press the jump button & be grounded
func _apply_jump() -> void:
	if wants_to_jump and is_on_floor():
		velocity.y = JUMP_VELOCITY
	wants_to_jump = false

#converts player 2D vector input into 3D and applies it to velocity
func _apply_movement(delta: float) -> void:
	var direction := (transform.basis * Vector3(_input_dir.x, 0, _input_dir.y)).normalized()
	
	if wants_to_sprint and !wants_to_crouch and !wants_to_grab:
		direction *= SPRINT_SPEED
	#Crouching
	if wants_to_crouch:
		scale.y = lerp(scale.y, CROUCH_HEIGHT, CROUCH_SPEED * delta)
	else:
		scale.y = lerp(scale.y, PLAYER_HEIGHT, CROUCH_SPEED * delta)
	if is_on_floor():
		if direction:
			var target = direction * BASE_SPEED
			if direction.length() > 0.1:
				velocity.x = lerp(velocity.x, target.x, ACCEL * delta)
				velocity.z = lerp(velocity.z, target.z, ACCEL * delta)
			else:
				velocity.x = lerp(velocity.x, 0.0, DECEL * delta)
				velocity.z = lerp(velocity.z, 0.0, DECEL * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, BASE_SPEED)
			velocity.z = move_toward(velocity.z, 0, BASE_SPEED)


func _apply_UI() -> void:
	if mouse_locked:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _apply_camera_motion(delta: float) -> void:
	#movement speed for bob (uses ground speed so vector2
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	
	if ground_speed > 0.1 and is_on_floor():
		bob_time += delta * bob_speed
		var bob_offset := sin(bob_time) * bob_amount
		camera.position.y = bob_offset
	else:
		camera.position.y = lerp(camera.position.y, 0.0, delta * 10.0)
	# ===== CAMERA SWAY =====
	# _input_dir.x is left/right relative to the player/camera
	sway_target = -_input_dir.x * sway_amount
	sway_current = lerp(sway_current, sway_target, delta * sway_smooth)
	camera.rotation.z = sway_current
