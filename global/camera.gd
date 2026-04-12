extends Camera3D

@export var target: CharacterBody3D
@export var offset: Vector3 = Vector3(0, 5, 6)
@export var smoothness: float = 0.1
@export var mouse_sensitivity: float = 0.3
@export var joy_sensitivity: float = 200.0

var current_angle: float = 0.0
var current_angle_deg: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	# rotación con mouse
	if event is InputEventMouseMotion:
		current_angle -= event.relative.x * mouse_sensitivity
	
	# liberar/capturar mouse con Escape
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	if not target:
		return
		
	if not GameManager.is_running:
		return
	
	# rotación con stick derecho del control
	var joy_x := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	if abs(joy_x) > 0.15:
		current_angle -= joy_x * joy_sensitivity * delta
	
	_update_camera(delta)

func _update_camera(delta: float) -> void:
	var angle_rad := deg_to_rad(current_angle)
	var rotated_offset := Vector3(
		offset.x * cos(angle_rad) - offset.z * sin(angle_rad),
		offset.y,
		offset.x * sin(angle_rad) + offset.z * cos(angle_rad)
	)
	
	var target_position := target.global_position + rotated_offset
	global_position = global_position.lerp(target_position, smoothness)
	look_at(target.global_position, Vector3.UP)
	
	# actualizar ángulo que lee el jugador
	current_angle_deg = current_angle
