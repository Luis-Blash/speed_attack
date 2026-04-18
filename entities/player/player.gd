extends CharacterBody3D

# --- configuración ---
@export var speed: float = 8.0
@export var gravity: float = 60.0
@export var attack_duration: float = 0.15
@export var jump_force: float = 15.0
@export var wall_jump_force: float = 12.0
@export var wall_slide_gravity: float = 0.5

# --- estado de pared ---
var wall_normal: Vector3 = Vector3.ZERO
var is_on_wall: bool = false
var can_wall_slide: bool = true

# --- dash ---
@export var dash_force: float = 30.0
@export var dash_duration: float = 0.1
@export var dash_cooldown: float = 0.4
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO

# --- state machine ---
enum State { IDLE, MOVE, ATTACK, WALL_SLIDE, DASH, DEAD }
var current_state: State = State.IDLE

# --- ataque ---
var attack_timer: float = 0.0

# --- referencias ---
@onready var attack_area: Area3D = $AttackArea
@onready var shape_cast: ShapeCast3D = $ShapeCast3D
@export var spawn_point: Marker3D
@export var camera: Camera3D
@export var shuriken_scene: PackedScene

func _ready() -> void:
	global_position = spawn_point.global_position
	attack_area.monitoring = false
	attack_area.body_entered.connect(_on_attack_hit)

func _physics_process(delta: float) -> void:
	if not GameManager.is_running:
		return
	_check_walls()
	_gravity_to_state(delta)
	_update_timers(delta)
	_handle_global_input()
	
	match current_state:
		State.IDLE:
			_state_idle()
		State.MOVE:
			_state_move()
		State.ATTACK:
			_state_attack(delta)
		State.WALL_SLIDE:
			_state_wall_slide()
		State.DASH:
			_state_dash(delta)
		State.DEAD:
			_state_dead()
	
	move_and_slide()

func _handle_global_input() -> void:
	if current_state == State.ATTACK or current_state == State.DEAD:
		return
	
	# salto normal desde el piso
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
	
	# salto desde pared — solo con just_pressed, nunca con is_pressed
	if Input.is_action_just_pressed("jump") and current_state == State.WALL_SLIDE:
		_wall_jump()
	
	if Input.is_action_just_pressed("attack_1"):
		_start_attack()
	
	if Input.is_action_just_pressed("throw"):
		_throw_shuriken()
		
	#if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		#_start_dash()

# --- estados ---
func _state_idle() -> void:
	velocity.x = 0
	velocity.z = 0
	if get_input_direction().length() > 0.1:
		current_state = State.MOVE
	if is_on_wall and not is_on_floor():
		current_state = State.WALL_SLIDE

func _state_move() -> void:
	var direction := get_input_direction()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	if direction.length() > 0.1:
		var target_angle := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 0.15)
	
	if direction.length() < 0.1:
		current_state = State.IDLE
	
	if is_on_wall and not is_on_floor():
		current_state = State.WALL_SLIDE

func _state_wall_slide() -> void:
	velocity.x = 0
	velocity.z = 0
	
	if velocity.y > 0:
		velocity.y = 0
	
	# rotar según input o hacia afuera de la pared
	var input_dir := get_input_direction()
	input_dir.y = 0
	
	var look_dir: Vector3
	if input_dir.length() > 0.1:
		look_dir = input_dir
	else:
		look_dir = -wall_normal
		look_dir.y = 0
	
	if look_dir.length() > 0.1:
		var target_angle := atan2(-look_dir.x, -look_dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 0.2)
	
	if is_on_floor():
		current_state = State.IDLE
	
	if not is_on_wall:
		current_state = State.IDLE

func _state_attack(delta: float) -> void:
	attack_timer -= delta
	if attack_timer <= 0.0:
		attack_area.monitoring = false
		current_state = State.IDLE

func _start_dash() -> void:
	# si hay input dashea hacia ese lado, si no hacia donde mira
	var dir := get_input_direction()
	if dir.length() < 0.1:
		dir = -global_transform.basis.z
	dash_direction = dir.normalized()
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	current_state = State.DASH

func _state_dash(delta: float) -> void:
	dash_timer -= delta
	velocity.x = dash_direction.x * dash_force
	velocity.z = dash_direction.z * dash_force
	velocity.y = 0.0  # dash horizontal puro, sin gravedad
	
	if dash_timer <= 0.0:
		current_state = State.IDLE

func _update_timers(delta: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

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
	
	if not camera:
		return Vector3(input.x, 0, input.y)
	
	var angle := deg_to_rad(-camera.current_angle_deg)
	return Vector3(
		input.x * cos(angle) + input.y * sin(angle),
		0,
		-input.x * sin(angle) + input.y * cos(angle)
	)

func _check_walls() -> void:
	is_on_wall = false
	wall_normal = Vector3.ZERO
	
	# resetear can_wall_slide al tocar el suelo
	if is_on_floor():
		can_wall_slide = true
		return
		
	if not can_wall_slide:
		return
	
	for i in shape_cast.get_collision_count():
		var collider = shape_cast.get_collider(i)
		if collider.is_in_group("wall_jump"):
			wall_normal += shape_cast.get_collision_normal(i)
			is_on_wall = true

func _wall_jump() -> void:
	var input_dir := get_input_direction()
	input_dir.y = 0
	var toward_wall := input_dir.dot(-wall_normal)
	var jump_dir := input_dir - (-wall_normal * toward_wall)
	
	can_wall_slide = false
	is_on_wall = false
	current_state = State.MOVE
	
	if jump_dir.length() > 0.1:
		jump_dir = jump_dir.normalized()
		velocity.x = jump_dir.x * wall_jump_force
		velocity.z = jump_dir.z * wall_jump_force
		velocity.y = wall_jump_force
	else:
		velocity.x = wall_normal.x * 8.0
		velocity.z = wall_normal.z * 8.0
		velocity.y = wall_jump_force * 1.2
	
func _gravity_to_state(delta:float) ->void:
	if current_state == State.WALL_SLIDE:
		velocity.y -= wall_slide_gravity * delta
	elif not is_on_floor():
		velocity.y -= gravity * delta

func _throw_shuriken() -> void:
	if not shuriken_scene:
		return
	var shuriken = shuriken_scene.instantiate()
	get_tree().root.add_child(shuriken)
	shuriken.global_position = global_position + (-global_transform.basis.z * 1.5) + Vector3(0, 0.5, 0)
	shuriken.direction = -global_transform.basis.z

func _start_attack() -> void:
	current_state = State.ATTACK
	attack_timer = attack_duration
	attack_area.monitoring = true

func die() -> void:
	current_state = State.DEAD
	global_position = spawn_point.global_position
	velocity = Vector3.ZERO
	await get_tree().create_timer(0.5).timeout
	current_state = State.IDLE

# --- señales ---
func _on_attack_hit(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		body.die()
