extends CharacterBody3D

enum State { IDLE, MOVE, WALL_SLIDE, DASH, DEAD }
var current_state: State = State.IDLE

@export var gravity: float = 55.0
@export var spawn_point: Marker3D

@onready var movement: MovementComponent = $MovementComponent
@onready var jump: JumpComponent = $JumpComponent
@onready var dash: DashComponent = $DashComponent
@onready var wall_slide: WallSlideComponent = $WallSlideComponent
@onready var attack: AttackComponent = $AttackComponent
@onready var throw_component: ThrowComponent = $ThrowComponent



func _ready() -> void:
	if spawn_point:
		global_position = spawn_point.global_position

func _physics_process(delta: float) -> void:
	if not GameManager.is_running:
		return
	
	jump.update(delta)
	dash.update(delta)
	attack.update(delta)
	wall_slide.update(delta)
	
	# gravedad
	if current_state == State.WALL_SLIDE:
		wall_slide.apply_gravity(delta)
	elif not is_on_floor():
		velocity.y -= gravity * delta
	
	var direction := movement.get_input_direction()
	var direction_flat := Vector3(direction.x, 0, direction.z)
	
	# input
	if Input.is_action_just_pressed("jump"):
		if current_state == State.WALL_SLIDE:
			wall_slide.try_wall_jump(direction_flat)
			current_state = State.MOVE
		else:
			jump.try_jump()
	
	if Input.is_action_just_pressed("dash"):
		dash.try_dash(direction)
		
	if Input.is_action_just_pressed("attack_1"):
		attack.try_attack()
		
	if Input.is_action_just_pressed("throw") and current_state != State.DEAD:
		throw_component.try_throw()
	
	# state machine
	if dash.is_dashing:
		current_state = State.DASH
	elif current_state == State.DASH:
		current_state = State.IDLE
	
	match current_state:
		State.IDLE:
			velocity.x = 0
			velocity.z = 0
			if direction.length() > 0.1:
				current_state = State.MOVE
			if wall_slide.is_on_wall and not is_on_floor():
				current_state = State.WALL_SLIDE
		State.MOVE:
			movement.process_movement(direction)
			if direction.length() < 0.1:
				current_state = State.IDLE
			if wall_slide.is_on_wall and not is_on_floor():
				current_state = State.WALL_SLIDE
		State.WALL_SLIDE:
			velocity.x = 0
			velocity.z = 0
			if velocity.y > 0:
				velocity.y = 0
			wall_slide.update_look_direction(direction_flat)
			if is_on_floor():
				current_state = State.IDLE
			if not wall_slide.is_on_wall:
				current_state = State.IDLE
		State.DASH:
			pass
		State.DEAD:
			velocity.x = 0
			velocity.z = 0
	
	move_and_slide()

func die() -> void:
	current_state = State.DEAD
	if spawn_point:
		global_position = spawn_point.global_position
	velocity = Vector3.ZERO
	await get_tree().create_timer(0.5).timeout
	current_state = State.IDLE
