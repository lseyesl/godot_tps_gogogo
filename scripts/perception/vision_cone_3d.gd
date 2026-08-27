class_name GameVisionCone3D
extends MeshInstance3D

@export var sensor_path: NodePath
@export_range(4, 128, 1) var ray_count: int = 128
@export var cone_color := Color(0.18, 0.72, 0.58, 0.22)

var _immediate_mesh: ImmediateMesh
var _material: StandardMaterial3D

@onready var _sensor: GameVisionSensor3D = get_node(sensor_path) as GameVisionSensor3D

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		visible = false
		set_physics_process(false)
		return
	_immediate_mesh = ImmediateMesh.new()
	mesh = _immediate_mesh
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.albedo_color = cone_color
	_material.no_depth_test = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _physics_process(_delta: float) -> void:
	_rebuild_cone()

func _rebuild_cone() -> void:
	if _sensor == null or _sensor.observer == null:
		return
	_immediate_mesh.clear_surfaces()
	var half_angle := _sensor.field_of_view_degrees * 0.5
	var boundary_points := PackedVector3Array()
	for index in range(ray_count + 1):
		var angle := lerpf(-half_angle, half_angle, float(index) / float(ray_count))
		boundary_points.append(_point_for_angle(angle))
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _material)
	for index in ray_count:
		_add_vertex(Vector3.ZERO)
		_add_vertex(boundary_points[index])
		_add_vertex(boundary_points[index + 1])
	_immediate_mesh.surface_end()

func _point_for_angle(angle_degrees: float) -> Vector3:
	var local_direction := Vector3(sin(deg_to_rad(angle_degrees)), 0.0, -cos(deg_to_rad(angle_degrees)))
	var world_direction := (_sensor.observer.global_basis * local_direction).normalized()
	world_direction.y = 0.0
	world_direction = world_direction.normalized()
	var distance := _sensor.get_occluded_distance(world_direction)
	var world_point := _sensor.observer.global_position + world_direction * distance
	world_point.y = global_position.y
	return to_local(world_point)

func _add_vertex(vertex: Vector3) -> void:
	_immediate_mesh.surface_set_normal(Vector3.UP)
	_immediate_mesh.surface_add_vertex(vertex)
