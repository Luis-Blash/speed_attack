extends CharacterBody3D

# --- configuración ---
@export var speed: float = 4.0
@export var vision_angle: float = 60.0

# --- estado ---
enum State { IDLE, CHASE }
var current_state: State = State.IDLE
var player: CharacterBody3D = null

# --- referencias ---
@onready var vision_area: Area3D = $VisionArea
@onready var raycast: RayCast3D = $RayCast3D

# --- gravedad ---
var gravity: float = 20.0

func _ready() -> void:
	vision_area.body_entered.connect(_on_vision_entered)
	vision_area.body_exited.connect(_on_vision_exited)

func _physics_process(delta: float) -> void:
	# aplicar gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	match current_state:
		State.IDLE:
			_state_idle()
		State.CHASE:
			_state_chase(delta)
	
	move_and_slide()

func _state_idle() -> void:
	velocity.x = 0
	velocity.z = 0
	# verificar si puede ver al jugador
	if player and _can_see_player():
		current_state = State.CHASE

func _state_chase(delta: float) -> void:
	if not player:
		current_state = State.IDLE
		return
	
	# moverse hacia el jugador
	var direction := (player.global_position - global_position)
	direction.y = 0
	direction = direction.normalized()
	
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	# rotación suave hacia el jugador
	var target_basis := Basis.looking_at(direction, Vector3.UP)
	#0.05 → muy lento, casi cinematográfico, 0.1 → suave pero responsivo, 0.3 → rápido pero sin brusquedad
	global_transform.basis = global_transform.basis.slerp(target_basis, 0.1)
	
	# si pierde visión vuelve a idle
	if not _can_see_player():
		current_state = State.IDLE

func _can_see_player() -> bool:
	if not player:
		return false
	
	# verificar ángulo de visión
	var to_player := (player.global_position - global_position).normalized()
	var forward := -global_transform.basis.z
	var angle := rad_to_deg(forward.angle_to(to_player))
	
	if angle > vision_angle:
		return false
	
	# verificar línea de visión con raycast
	var local_target := to_player * 6.0
	raycast.target_position = raycast.to_local(global_position + local_target)
	raycast.force_raycast_update()
	
	if not raycast.is_colliding():
		return true
	
	return raycast.get_collider() == player

func _on_vision_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body

func _on_vision_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = null
		current_state = State.IDLE
