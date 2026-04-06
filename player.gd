extends CharacterBody3D

@export var speed: float = 8.0
@export var gravity: float = 20.0

func get_input_direction() -> Vector3:
	var input := Vector2.ZERO
	
	input.x = Input.get_axis("ui_left", "ui_right")
	input.y = Input.get_axis("ui_up", "ui_down")
	
	if input.length() > 1.0:
		input = input.normalized()
	
	var direction := Vector3(
		input.x,  
		0,
		input.y  
	)
	
	return direction

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var direction := get_input_direction()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	if direction.length() > 0.1:
		var target_angle := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 0.15)
	
	move_and_slide()
