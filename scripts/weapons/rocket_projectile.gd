class_name GameRocketProjectile
extends Node3D

signal exploded(position: Vector3)

@export_flags_3d_physics var hit_mask: int = 11

var direction := Vector3.FORWARD
var speed_meters_per_second: float = 10.0
var maximum_distance_meters: float = 16.0
var explosion_radius_meters: float = 4.0
var explosion_center_damage: float = 5.0
var explosion_edge_damage: float = 1.0
var source: CollisionObject3D

var _distance_travelled: float = 0.0
var _has_exploded := false

func _physics_process(delta: float) -> void:
	if _has_exploded:
		return
	var step_distance := minf(speed_meters_per_second * delta, maximum_distance_meters - _distance_travelled)
	var next_position := global_position + direction * step_distance
	var query := PhysicsRayQueryParameters3D.create(global_position, next_position, hit_mask)
	query.collide_with_areas = true
	if source != null:
		query.exclude = [source.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position = hit.position
		_explode()
		return
	global_position = next_position
	_distance_travelled += step_distance
	if _distance_travelled >= maximum_distance_meters - 0.001:
		_explode()

func _explode() -> void:
	if _has_exploded:
		return
	_has_exploded = true
	var hub := GameEnvironmentReactionHub.find_in_tree(self)
	if hub != null:
		hub.request_explosion(
			global_position,
			explosion_radius_meters,
			explosion_center_damage,
			explosion_edge_damage,
			source
		)
	exploded.emit(global_position)
	queue_free()
