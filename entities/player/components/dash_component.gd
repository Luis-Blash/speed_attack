class_name DashComponent
extends Node

@export var dash_force: float = 30.0
@export var dash_duration: float = 0.1
@export var dash_cooldown: float = 0.4

signal dash_started
signal dash_ended

var _player: CharacterBody3D
var _dash_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var is_dashing: bool = false

func _ready() -> void:
	_player = get_parent()

func update(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
	
	if is_dashing:
		_dash_timer -= delta
		_player.velocity.x = _dash_direction.x * dash_force
		_player.velocity.z = _dash_direction.z * dash_force
		_player.velocity.y = 0.0
		
		if _dash_timer <= 0.0:
			is_dashing = false
			dash_ended.emit()

func try_dash(direction: Vector3) -> bool:
	if _cooldown_timer > 0.0:
		return false
	
	_dash_direction = direction if direction.length() > 0.1 else -_player.global_transform.basis.z
	_dash_direction = _dash_direction.normalized()
	_dash_timer = dash_duration
	_cooldown_timer = dash_cooldown
	is_dashing = true
	dash_started.emit()
	return true

func can_dash() -> bool:
	return _cooldown_timer <= 0.0
