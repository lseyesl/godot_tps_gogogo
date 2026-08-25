class_name GameVisionSensor3D
extends Node3D

@export var observer_path: NodePath
@export_range(0.1, 100.0, 0.1) var view_distance: float = 16.0
@export_range(1.0, 360.0, 1.0) var field_of_view_degrees: float = 120.0
@export_range(0.0, 4.0, 0.05) var eye_height: float = 1.05
@export_range(0.0, 4.0, 0.05) var target_height: float = 0.9
@export_flags_3d_physics var occlusion_mask: int = 2

@onready var observer: Node3D = _resolve_observer()

func can_see(target: Node3D) -> bool:
	if target == null:
		return false
	var target_position := target.global_position + Vector3.UP * target_height
	return is_position_in_view(target_position) and has_clear_line_to_position(target_position)

func is_position_in_view(target_position: Vector3) -> bool:
	if observer == null:
		return false
	var planar_delta := target_position - get_eye_position()
	planar_delta.y = 0.0
	var distance := planar_delta.length()
	if distance <= 0.001 or distance > view_distance:
		return false
	var forward := get_forward_direction()
	var minimum_dot := cos(deg_to_rad(field_of_view_degrees * 0.5))
	return forward.dot(planar_delta / distance) >= minimum_dot

func has_clear_line_to(target: Node3D) -> bool:
	if target == null:
		return false
	return has_clear_line_to_position(target.global_position + Vector3.UP * target_height)

func has_clear_line_to_position(target_position: Vector3) -> bool:
	if observer == null:
		return false
	var query := PhysicsRayQueryParameters3D.create(get_eye_position(), target_position, occlusion_mask)
	if observer is CollisionObject3D:
		query.exclude = [(observer as CollisionObject3D).get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func get_occluded_distance(world_direction: Vector3) -> float:
	var direction := world_direction.normalized()
	var start := get_eye_position()
	var query := PhysicsRayQueryParameters3D.create(
		start,
		start + direction * view_distance,
		occlusion_mask
	)
	if observer is CollisionObject3D:
		query.exclude = [(observer as CollisionObject3D).get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return view_distance
	return start.distance_to(hit.position)

func get_eye_position() -> Vector3:
	if observer == null:
		return global_position
	return observer.global_position + Vector3.UP * eye_height

func get_forward_direction() -> Vector3:
	if observer == null:
		return Vector3.FORWARD
	var forward := -observer.global_basis.z
	forward.y = 0.0
	return forward.normalized()

func _resolve_observer() -> Node3D:
	if observer_path.is_empty():
		return get_parent() as Node3D
	return get_node(observer_path) as Node3D
