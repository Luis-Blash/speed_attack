class_name MovementComponent
extends Node

@export var speed: float = 16.0
@export var rotation_speed: float = 0.15
@export var camera: Camera3D

var _player: CharacterBody3D

func _ready() -> void:
	_player = get_parent()

func process_movement(direction: Vector3) -> void:
	_player.velocity.x = direction.x * speed
	_player.velocity.z = direction.z * speed
	
	if direction.length() > 0.1:
		var target_angle := atan2(-direction.x, -direction.z)
		_player.rotation.y = lerp_angle(_player.rotation.y, target_angle, rotation_speed)

func get_input_direction() -> Vector3:
	var input := Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")
	
	if input.length() > 1.0:
		input = input.normalized()
	
	if not camera:
		return Vector3(input.x, 0, input.y)
	
	var angle := deg_to_rad(-camera.current_angle_deg)
	return Vector3(
		input.x * cos(angle) + input.y * sin(angle),
		0,
		-input.x * sin(angle) + input.y * cos(angle)
	)
