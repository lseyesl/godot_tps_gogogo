class_name GameEnvironmentReactionHub
extends Node3D

signal explosion_resolved(position: Vector3, radius: float, source: Node)
signal fire_propagated(source: Node3D)

@export_flags_3d_physics var wall_mask: int = 2
@export var adjacency_meters: float = 2.0
@export var adjacency_tolerance: float = 0.08

var _explosion_queue: Array[Dictionary] = []
var _processing_explosions := false
var _fire_queue: Array[Node3D] = []
var _processing_fire := false

func _ready() -> void:
	add_to_group("environment_reaction_hub")

func request_explosion(
	position: Vector3,
	radius: float,
	center_damage: float,
	edge_damage: float,
	source: Node = null
) -> void:
	if radius <= 0.0 or center_damage <= 0.0:
		return
	_explosion_queue.append({
		"position": position,
		"radius": radius,
		"center_damage": center_damage,
		"edge_damage": maxf(0.0, edge_damage),
		"source": source,
	})
	if _processing_explosions:
		return
	_processing_explosions = true
	while not _explosion_queue.is_empty():
		_resolve_explosion(_explosion_queue.pop_front())
	_processing_explosions = false

func request_fire_propagation(source: Node3D) -> void:
	if source == null or not is_instance_valid(source):
		return
	_fire_queue.append(source)
	if _processing_fire:
		return
	_processing_fire = true
	while not _fire_queue.is_empty():
		var current := _fire_queue.pop_front() as Node3D
		if current != null and is_instance_valid(current):
			_propagate_fire_from(current)
	_processing_fire = false

func apply_fire_damage(position: Vector3, radius: float, source: Node) -> void:
	for target in _get_sorted_group_nodes("fire_damage_targets"):
		if not target is Node3D or not target.has_method("apply_damage"):
			continue
		if _planar_distance(position, (target as Node3D).global_position) <= radius:
			target.call("apply_damage", 1.0, source)

static func find_in_tree(node: Node) -> GameEnvironmentReactionHub:
	if node == null or node.get_tree() == null:
		return null
	return node.get_tree().get_first_node_in_group("environment_reaction_hub") as GameEnvironmentReactionHub

func _resolve_explosion(event: Dictionary) -> void:
	var position: Vector3 = event.position
	var radius: float = event.radius
	var source: Node = event.source
	var damage_snapshot: Array[Dictionary] = []
	for target in _get_sorted_group_nodes("explosion_targets"):
		if not target is Node3D or not target.has_method("apply_damage"):
			continue
		var target_position := (target as Node3D).global_position + Vector3.UP * 0.9
		var distance := _planar_distance(position, target_position)
		if distance > radius or _is_explosion_blocked(position, target as Node3D, source):
			continue
		var ratio := clampf(distance / radius, 0.0, 1.0)
		var damage := lerpf(event.center_damage, event.edge_damage, ratio)
		damage_snapshot.append({"target": target, "damage": damage})
	for entry in damage_snapshot:
		var target: Node = entry.target
		if target != null and is_instance_valid(target):
			target.call("apply_damage", entry.damage, source)
	var sound_hub := GameSoundEventHub.find_in_tree(self)
	if sound_hub != null:
		sound_hub.emit_sound_event(
			position,
			40.0,
			GameSoundEventHub.Priority.EXPLOSION,
			source
		)
	explosion_resolved.emit(position, radius, source)

func _propagate_fire_from(source: Node3D) -> void:
	for target in _get_sorted_group_nodes("flammable_modules"):
		if target == source or not target is Node3D or not target.has_method("ignite_from_fire"):
			continue
		var distance := _planar_distance(source.global_position, (target as Node3D).global_position)
		if distance > 0.01 and distance <= adjacency_meters + adjacency_tolerance:
			target.call("ignite_from_fire", source)
	fire_propagated.emit(source)

func _is_explosion_blocked(origin: Vector3, target: Node3D, source: Node) -> bool:
	var excluded: Array[RID] = []
	if source is CollisionObject3D:
		excluded.append((source as CollisionObject3D).get_rid())
	for _attempt in 12:
		var query := PhysicsRayQueryParameters3D.create(
			origin,
			target.global_position + Vector3.UP * 0.9,
			wall_mask
		)
		query.exclude = excluded
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			return false
		var collider := hit.get("collider") as CollisionObject3D
		if collider == target:
			return false
		if (
			collider != null
			and collider.has_method("is_environment_obstacle_active")
			and not collider.call("is_environment_obstacle_active")
		):
			excluded.append(collider.get_rid())
			continue
		return true
	return true

func _get_sorted_group_nodes(group_name: StringName) -> Array[Node]:
	var nodes: Array[Node] = []
	for node in get_tree().get_nodes_in_group(group_name):
		nodes.append(node)
	nodes.sort_custom(func(first: Node, second: Node) -> bool:
		return first.get_instance_id() < second.get_instance_id()
	)
	return nodes

func _planar_distance(first: Vector3, second: Vector3) -> float:
	var delta := first - second
	delta.y = 0.0
	return delta.length()
