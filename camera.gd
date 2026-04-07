extends Camera3D

@export var target: CharacterBody3D
@export var offset: Vector3 = Vector3(0, 8, 4)
@export var smoothness: float = 0.1
@export var rotation_speed: float = 5.0

var current_angle: float = 0.0
var target_angle: float = 0.0
var is_rotating: bool = false
var current_angle_deg: float = 0.0  # ← agregar esta línea

func _physics_process(delta: float) -> void:
	if not target:
		return
	_handle_rotation_input()
	_update_camera(delta)

func _handle_rotation_input() -> void:
	if is_rotating:
		return
	if Input.is_action_just_pressed("camera_left"):
		target_angle += 90.0
		is_rotating = true
	if Input.is_action_just_pressed("camera_right"):
		target_angle -= 90.0
		is_rotating = true

func _update_camera(delta: float) -> void:
	current_angle = lerp_angle(
		deg_to_rad(current_angle),
		deg_to_rad(target_angle),
		rotation_speed * delta
	)
	current_angle = rad_to_deg(current_angle)
	
	if abs(current_angle - target_angle) < 0.5:
		current_angle = target_angle
		is_rotating = false
	
	var angle_rad := deg_to_rad(current_angle)
	var rotated_offset := Vector3(
		offset.x * cos(angle_rad) - offset.z * sin(angle_rad),
		offset.y,
		offset.x * sin(angle_rad) + offset.z * cos(angle_rad)
	)
	
	var target_position := target.global_position + rotated_offset
	global_position = global_position.lerp(target_position, smoothness)
	look_at(target.global_position, Vector3.UP)
	
	# actualizar el ángulo que lee el jugador
	current_angle_deg = current_angle  # ← agregar esta línea
