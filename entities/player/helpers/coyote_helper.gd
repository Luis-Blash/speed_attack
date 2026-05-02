class_name CoyoteHelper
extends Node

@export var coyote_time: float = 0.12

var _timer: float = 0.0
var _used: bool = false

func update(delta: float, on_floor: bool) -> void:
	if on_floor:
		_timer = coyote_time
		_used = false
	elif _timer > 0.0 and not _used:
		_timer -= delta
		if _timer < 0.0:
			_timer = 0.0

func can_jump() -> bool:
	return _timer > 0.0

func consume() -> void:
	_timer = 0.0
	_used = true
