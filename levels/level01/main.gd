extends Node3D

@onready var timer_label: Label = $CanvasLayer/VBoxContainer/TimerLabel
@onready var color_rect: ColorRect = $CanvasLayer/Control/ColorRect
@onready var time_label: Label = $CanvasLayer/Control/ColorRect/VBoxContainer/TimeLabel
@onready var rank_label: Label = $CanvasLayer/Control/ColorRect/VBoxContainer/RankLabel
@onready var retry_button: Button = $CanvasLayer/Control/ColorRect/VBoxContainer/RetryButton

func _ready() -> void:
	# pasar referencias UI al GameManager
	GameManager.timer_label = timer_label
	GameManager.color_rect = color_rect
	GameManager.time_label = time_label
	GameManager.rank_label = rank_label
	
	# iniciar nivel con el conteo de enemigos
	var enemy_count := get_tree().get_nodes_in_group("enemy").size()
	GameManager.start_level(enemy_count)
	
	retry_button.pressed.connect(GameManager.retry)
