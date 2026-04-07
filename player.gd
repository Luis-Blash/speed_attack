extends CharacterBody3D

# --- configuración ---
@export var speed: float = 8.0
@export var gravity: float = 60.0
@export var attack_duration: float = 0.15
@export var jump_force: float = 15.0

# --- state machine ---
enum State { IDLE, MOVE, ATTACK, DEAD }
var current_state: State = State.IDLE

# --- ataque ---
var attack_timer: float = 0.0

# --- referencias ---
@onready var attack_area: Area3D = $AttackArea

func _ready() -> void:
	attack_area.monitoring = false
	attack_area.body_entered.connect(_on_attack_hit)

func _physics_process(delta: float) -> void:
	# gravedad siempre activa sin importar el estado
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	_handle_global_input()
	
	match current_state:
		State.IDLE:
			_state_idle()
		State.MOVE:
			_state_move()
		State.ATTACK:
			_state_attack(delta)
		State.DEAD:
			_state_dead()
	
	move_and_slide()

# --- estados ---

func _handle_global_input() -> void:
	if current_state == State.ATTACK or current_state == State.DEAD:
		return
	
	# salto
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
	
	# ataque
	if Input.is_action_just_pressed("attack_1"):
		_start_attack()
	
func _state_idle() -> void:
	velocity.x = 0
	velocity.z = 0
	if get_input_direction().length() > 0.1:
		current_state = State.MOVE

func _state_move() -> void:
	var direction := get_input_direction()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if direction.length() > 0.1:
		var target_angle := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 0.15)
	if direction.length() < 0.1:
		current_state = State.IDLE

func _state_attack(delta: float) -> void:
	# durante el ataque no se mueve
	velocity.x = 0
	velocity.z = 0
	
	attack_timer -= delta
	if attack_timer <= 0.0:
		attack_area.monitoring = false
		current_state = State.IDLE

func _state_dead() -> void:
	velocity.x = 0
	velocity.z = 0

# --- helpers ---
func get_input_direction() -> Vector3:
	var input := Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")
	
	if input.length() > 1.0:
		input = input.normalized()
	
	return Vector3(input.x, 0, input.y)

func _start_attack() -> void:
	current_state = State.ATTACK
	attack_timer = attack_duration
	attack_area.monitoring = true

func die() -> void:
	current_state = State.DEAD

# --- señales ---
func _on_attack_hit(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		body.die()
