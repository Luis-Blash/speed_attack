extends Camera3D

@export var target: CharacterBody3D
@export var offset: Vector3 = Vector3(0, 8, 4)
@export var smoothness: float = 0.1

func _physics_process(delta: float) -> void:
	if not target:
		return
	
	var target_position := target.global_position + offset
	
	global_position = global_position.lerp(target_position, smoothness)
