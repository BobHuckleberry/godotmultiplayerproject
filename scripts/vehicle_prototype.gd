extends VehicleBody3D
class_name Vehicle

@onready var interactable: InteractableComponent = $InteractableComponent

@export var engine_force_value := 1200.0
@export var brake_force_value := 40.0
@export var max_steer_angle := 0.4  # radians (~23 degrees)

@onready var front_left_wheel: VehicleWheel3D = $FrontLeftWheel
@onready var front_right_wheel: VehicleWheel3D = $FrontRightWheel
@onready var rear_left_wheel: VehicleWheel3D = $BackLeftWheel
@onready var rear_right_wheel: VehicleWheel3D = $BackRightWheel

var throttle_input: float = 0.0
var steer_input: float = 0.0
var brake_input: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# tell the component who should handle the interaction
	interactable.interaction_owner = self
	

func on_interacted(interactor: InteractorComponent) -> void:
	print("Vehicle interacted with by:", interactor)
	var player = interactor.player
	player.enter_vehicle(self)

func apply_input(throttle: float, steer: float, brake_amount: float) -> void:
	throttle_input = throttle
	steer_input = steer
	brake_input = brake_amount

func _physics_process(_delta: float) -> void:
	var engine_force := throttle_input * engine_force_value
	var brake_force := brake_input * brake_force_value
	var steer_angle := steer_input * max_steer_angle

	_set_wheels(engine_force, brake_force, steer_angle)

	

	
func clear_input() -> void:
	throttle_input = 0.0
	steer_input = 0.0
	brake_input = 0.0
	_set_wheels(0.0, 0.0, 0.0)
	
func _set_wheels(engine_force: float, brake_force: float, steer_angle: float) -> void:
	# Engine on whatever wheels you want as drive wheels
	front_left_wheel.engine_force = engine_force
	front_right_wheel.engine_force = engine_force
	rear_left_wheel.engine_force = engine_force
	rear_right_wheel.engine_force = engine_force

	# Steering usually only on the front wheels
	front_left_wheel.steering = steer_angle
	front_right_wheel.steering = steer_angle

	# Brake all wheels
	front_left_wheel.brake = brake_force
	front_right_wheel.brake = brake_force
	rear_left_wheel.brake = brake_force
	rear_right_wheel.brake = brake_force
