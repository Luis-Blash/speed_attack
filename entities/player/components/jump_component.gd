class_name JumpComponent
extends Node

@export var jump_force: float = 15.0

signal jumped

var _player: CharacterBody3D
var _coyote: CoyoteHelper

func _ready() -> void:
	_player = get_parent()
	_coyote = _player.get_node("CoyoteHelper")

func update(delta: float) -> void:
	_coyote.update(delta, _player.is_on_floor())

func try_jump() -> bool:
	if _player.is_on_floor() or _coyote.can_jump():
		_player.velocity.y = jump_force
		_coyote.consume()
		jumped.emit()
		return true
	return false
