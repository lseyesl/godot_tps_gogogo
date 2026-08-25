class_name RocketWeapon
extends GameWeapon3D

const ROCKET_SCENE := preload("res://scenes/weapons/rocket_projectile.tscn")

@export_flags_3d_physics var hit_mask: int = 11

func _perform_shot(direction: Vector3) -> Dictionary:
	var rocket := ROCKET_SCENE.instantiate() as GameRocketProjectile
	rocket.direction = direction.normalized()
	rocket.speed_meters_per_second = definition.projectile_speed_meters_per_second
	rocket.maximum_distance_meters = definition.range_meters
	rocket.explosion_radius_meters = definition.explosion_radius_meters
	rocket.explosion_center_damage = definition.explosion_center_damage
	rocket.explosion_edge_damage = definition.explosion_edge_damage
	rocket.source = _owner_body
	var projectile_parent: Node = get_tree().current_scene
	if projectile_parent == null and _owner_body != null:
		projectile_parent = _owner_body.get_parent()
	if projectile_parent == null:
		projectile_parent = get_tree().root
	projectile_parent.add_child(rocket)
	rocket.global_position = global_position
	rocket.look_at(rocket.global_position + rocket.direction, Vector3.UP)
	return {"endpoint": get_aim_endpoint(direction), "hit": false}

func get_aim_endpoint(direction: Vector3) -> Vector3:
	if direction.length_squared() <= 0.0001:
		return global_position
	var normalized := direction.normalized()
	var query := PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + normalized * definition.range_meters,
		hit_mask
	)
	if _owner_body != null:
		query.exclude = [_owner_body.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.get("position", global_position + normalized * definition.range_meters)
