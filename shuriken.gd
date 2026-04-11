extends RigidBody3D

@export var speed: float = 20.0
@export var lifetime: float = 3.0

@onready var area: Area3D = $Area3D

const WALL_GROUPS = ["wall", "wall_jump"]

var direction: Vector3 = Vector3.ZERO

func _ready() -> void:
	area.body_entered.connect(_on_hit)
	await get_tree().process_frame
	linear_velocity = direction * speed
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_hit(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		body.die()
		queue_free()
		
	elif WALL_GROUPS.any(func(g): return body.is_in_group(g)):
		queue_free()
