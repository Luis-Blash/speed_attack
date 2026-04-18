extends Camera3D

@export var target: CharacterBody3D
@export var offset: Vector3 = Vector3(0, 5, 6)
@export var smoothness: float = 0.1
@export var mouse_sensitivity: float = 0.1
@export var joy_sensitivity: float = 200.0

var current_angle: float = 0.0
var current_angle_deg: float = 0.0

var _occluded_objects: Array[MeshInstance3D] = []
var _original_materials: Dictionary = {}
var _duplicated_materials: Dictionary = {}
@export var occlusion_alpha: float = 0.2
@export var occlusion_speed: float = 5.0
@onready var OcclusionRay: RayCast3D = $OcclusionRay

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GameManager.level_complete.connect(_on_level_complete)

func _on_level_complete() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		current_angle -= event.relative.x * mouse_sensitivity
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	if not target:
		return
	if not GameManager.is_running:
		return
	
	# rotación con stick derecho del control
	var joy_x := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	if abs(joy_x) > 0.15:
		current_angle -= joy_x * joy_sensitivity * delta
	
	_update_camera(delta)
	_update_occlusion()

func _update_camera(_delta: float) -> void:
	var angle_rad := deg_to_rad(current_angle)
	var rotated_offset := Vector3(
		offset.x * cos(angle_rad) - offset.z * sin(angle_rad),
		offset.y,
		offset.x * sin(angle_rad) + offset.z * cos(angle_rad)
	)
	global_position = global_position.lerp(target.global_position + rotated_offset, smoothness)
	look_at(target.global_position, Vector3.UP)
	current_angle_deg = current_angle
	
func _exit_tree() -> void:
	# liberar materiales al cambiar de nivel
	_original_materials.clear()
	_duplicated_materials.clear()
	_occluded_objects.clear()
	
func _update_occlusion() -> void:
	var still_occluded: Array[MeshInstance3D] = []
	
	# detectar todos los objetos entre cámara y player
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position, target.global_position)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	# lanzar múltiples rays para pasar por todos los obstáculos
	var from := global_position
	var excluded: Array[RID] = []
	
	for _i in range(10):
		query = PhysicsRayQueryParameters3D.create(from, target.global_position)
		query.exclude = excluded
		var result := space.intersect_ray(query)
		if result.is_empty():
			break
		var hit_body: Node3D = result["collider"] as Node3D
		var mesh_node := hit_body.get_parent() as MeshInstance3D
		# si el padre no es MeshInstance3D, ignorar y seguir el ray
		if mesh_node != null and mesh_node.is_in_group("wall_occlusion"):
			still_occluded.append(mesh_node)
		excluded.append(result["rid"])
		from = result["position"]

	
	# preparar material duplicado en objetos nuevos
	for obj in still_occluded:
		if not _occluded_objects.has(obj):
			var mat: BaseMaterial3D = obj.material_override as BaseMaterial3D
			if mat == null:
				continue
			var id: int = obj.get_instance_id()
			_original_materials[id] = mat
			var m: BaseMaterial3D = mat.duplicate() as BaseMaterial3D
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			obj.material_override = m
			_duplicated_materials[id] = m
	
	# interpolar alpha en todos los objetos conocidos
	var delta: float = get_physics_process_delta_time()
	for id in _duplicated_materials:
		var m: BaseMaterial3D = _duplicated_materials[id] as BaseMaterial3D
		if m == null:
			continue
		var obj: MeshInstance3D = instance_from_id(id) as MeshInstance3D
		if obj == null:
			continue
		var target_alpha: float = occlusion_alpha if still_occluded.has(obj) else 1.0
		m.albedo_color.a = lerp(m.albedo_color.a, target_alpha, occlusion_speed * delta)
		if not still_occluded.has(obj) and m.albedo_color.a >= 0.99:
			obj.material_override = _original_materials.get(id)
	
	_occluded_objects = still_occluded
	
