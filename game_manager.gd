extends Node

# --- cronómetro ---
var elapsed_time: float = 0.0
var is_running: bool = true

# --- enemigos ---
var enemies_alive: int = 0

# --- UI referencias ---
var timer_label: Label = null
var color_rect: ColorRect = null
var time_label: Label = null
var rank_label: Label = null

func start_level(enemy_count: int) -> void:
	enemies_alive = enemy_count
	elapsed_time = 0.0
	is_running = true

func _process(delta: float) -> void:
	if not is_running or timer_label == null:
		return
	elapsed_time += delta
	timer_label.text = _format_time(elapsed_time)

func enemy_died() -> void:
	enemies_alive -= 1
	if enemies_alive <= 0:
		_level_complete()

func _level_complete() -> void:
	is_running = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if time_label:
		time_label.text = "Tiempo: " + _format_time(elapsed_time)
	if rank_label:
		rank_label.text = "Rank: " + _get_rank(elapsed_time)
	if color_rect:
		color_rect.visible = true

func _get_rank(time: float) -> String:
	if time < 15.0:
		return "S"
	elif time < 30.0:
		return "A"
	elif time < 60.0:
		return "B"
	else:
		return "C"

func _format_time(time: float) -> String:
	var seconds := int(time)
	var milliseconds := int((time - seconds) * 100)
	return "%02d:%02d" % [seconds, milliseconds]

func retry() -> void:
	elapsed_time = 0.0
	is_running = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if color_rect:
		color_rect.visible = false
	get_tree().reload_current_scene()
