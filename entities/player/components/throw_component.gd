class_name ThrowComponent
extends Node

@export var shuriken_scene: PackedScene
@export var throw_offset: float = 1.5
@export var throw_height: float = 0.5

signal thrown

var _player: CharacterBody3D

func _ready() -> void:
	_player = get_parent()

func try_throw() -> void:
	if not shuriken_scene:
		return
	
	var shuriken = shuriken_scene.instantiate()
	_player.get_tree().root.add_child(shuriken)
	shuriken.global_position = _player.global_position \
		+ (-_player.global_transform.basis.z * throw_offset) \
		+ Vector3(0, throw_height, 0)
	shuriken.direction = -_player.global_transform.basis.z
	thrown.emit()
