class_name HitscanWeapon
extends GameWeapon3D

@export_flags_3d_physics var hit_mask: int = 10

func _perform_shot(direction: Vector3) -> Dictionary:
	var hit := _query_trajectory(direction)
	var endpoint: Vector3 = hit.get("position", global_position + direction * definition.range_meters)
	var damaged := false
	var target: Object
	if not hit.is_empty():
		var collider := hit.get("collider") as Object
		if collider != null and collider.has_method("apply_damage"):
			damaged = float(collider.call("apply_damage", definition.damage, _owner_body)) > 0.0
			target = collider
	return {"endpoint": endpoint, "hit": not hit.is_empty(), "damaged": damaged, "target": target, "damage": definition.damage}

func get_aim_endpoint(direction: Vector3) -> Vector3:
	if definition == null or direction.length_squared() <= 0.0001:
		return global_position
	var normalized_direction := direction.normalized()
	var hit := _query_trajectory(normalized_direction)
	return hit.get("position", global_position + normalized_direction * definition.range_meters)

func _query_trajectory(direction: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + direction * definition.range_meters,
		hit_mask
	)
	query.collide_with_areas = true
	if _owner_body != null:
		query.exclude = [_owner_body.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)
