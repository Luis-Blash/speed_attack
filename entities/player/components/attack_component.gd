class_name AttackComponent
extends Node3D

@export var attack_duration: float = 0.15

signal attack_started
signal attack_ended

var _player: CharacterBody3D
var _area: Area3D
var _view: MeshInstance3D

var is_attacking: bool = false
var _timer: float = 0.0

func _ready() -> void:
	_player = get_parent()
	_area = $Area3D
	_view = $Area3D/atacView
	
	_area.monitoring = false
	_view.visible = false
	_area.body_entered.connect(_on_hit)

func update(delta: float) -> void:
	if not is_attacking:
		return
	_timer -= delta
	if _timer <= 0.0:
		is_attacking = false
		_area.monitoring = false
		_view.visible = false
		attack_ended.emit()

func try_attack() -> void:
	if is_attacking:
		return
	is_attacking = true
	_timer = attack_duration
	_area.monitoring = true
	_view.visible = true
	attack_started.emit()

func _on_hit(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		body.die()
