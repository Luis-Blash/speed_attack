class_name WallSlideComponent
extends Node

@export var wall_stick_duration: float = 0.5
@export var wall_jump_force: float = 12.0
@export var wall_slide_gravity: float = 2.0
@export var wall_cooldown_duration: float = 0.5

signal wall_jumped

var _player: CharacterBody3D
var _shape_cast: ShapeCast3D

var wall_normal: Vector3 = Vector3.ZERO
var is_on_wall: bool = false
var can_wall_slide: bool = true
var _wall_stick_timer: float = 0.0
var _wall_cooldown_timer: float = 0.0

func _ready() -> void:
	_player = get_parent()
	_shape_cast = _player.get_node("ShapeCast3D")

func update(delta: float) -> void:
	_check_walls()
	
	if _wall_cooldown_timer > 0.0:
		_wall_cooldown_timer -= delta
		if _wall_cooldown_timer <= 0.0:
			_wall_cooldown_timer = 0.0
			can_wall_slide = true

func apply_gravity(delta: float) -> void:
	if _wall_stick_timer > 0.0:
		_wall_stick_timer -= delta
		_player.velocity.y = 0.0
	else:
		_player.velocity.y -= wall_slide_gravity * delta

func try_wall_jump(input_direction: Vector3) -> bool:
	if not is_on_wall:
		return false
	
	var toward_wall := input_direction.dot(-wall_normal)
	var jump_dir := input_direction - (-wall_normal * toward_wall)
	
	can_wall_slide = false
	is_on_wall = false
	_wall_cooldown_timer = wall_cooldown_duration
	
	if jump_dir.length() > 0.1:
		jump_dir = jump_dir.normalized()
		_player.velocity.x = jump_dir.x * wall_jump_force
		_player.velocity.z = jump_dir.z * wall_jump_force
		_player.velocity.y = wall_jump_force
	else:
		_player.velocity.x = wall_normal.x * 8.0
		_player.velocity.z = wall_normal.z * 8.0
		_player.velocity.y = wall_jump_force * 1.2
	
	wall_jumped.emit()
	return true

func update_look_direction(input_dir: Vector3) -> void:
	var look_dir: Vector3
	if input_dir.length() > 0.1:
		look_dir = input_dir
	else:
		look_dir = -wall_normal
		look_dir.y = 0
	
	if look_dir.length() > 0.1:
		var target_angle := atan2(-look_dir.x, -look_dir.z)
		_player.rotation.y = lerp_angle(_player.rotation.y, target_angle, 0.2)

func _check_walls() -> void:
	var previously_on_wall := is_on_wall
	is_on_wall = false
	wall_normal = Vector3.ZERO
	
	if _player.is_on_floor():
		can_wall_slide = true
		_wall_cooldown_timer = 0.0
		return
	
	if _wall_cooldown_timer > 0.0 or not can_wall_slide:
		return
	
	for i in _shape_cast.get_collision_count():
		var collider = _shape_cast.get_collider(i)
		if collider.is_in_group("wall_jump"):
			wall_normal += _shape_cast.get_collision_normal(i)
			is_on_wall = true
	
	if is_on_wall and not previously_on_wall:
		_wall_stick_timer = wall_stick_duration
