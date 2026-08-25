class_name GameCoverService3D
extends Node

@export_flags_3d_physics var occlusion_mask: int = 2
@export var body_height: float = 0.9

var _navigation: GameGridNavigation3D

func _ready() -> void:
	add_to_group("cover_service")
	_navigation = GameGridNavigation3D.find_in_tree(self)

func find_best_cover(
	guard_position: Vector3,
	threat_position: Vector3,
	search_radius_meters: float = 6.0
) -> Dictionary:
	_resolve_navigation()
	if _navigation == null:
		return {}
	var candidates: Dictionary = {}
	for blocker_cell in _navigation.get_blocked_cells_in_radius(guard_position, search_radius_meters):
		for candidate_cell in _navigation.get_cardinal_neighbors(blocker_cell):
			if _navigation.is_cell_blocked(candidate_cell) or candidates.has(candidate_cell):
				continue
			var cover_position := _navigation.cell_to_world(candidate_cell, guard_position.y)
			if _planar_distance(guard_position, cover_position) > search_radius_meters:
				continue
			if not is_position_covered(cover_position, threat_position):
				continue
			var path := _navigation.get_world_path(guard_position, cover_position)
			if path.is_empty():
				continue
			var peek_position := _find_peek_position(candidate_cell, threat_position, guard_position.y)
			if peek_position == Vector3.INF:
				continue
			var path_length := _navigation.get_world_path_length(path)
			candidates[candidate_cell] = {
				"cover_position": cover_position,
				"peek_position": peek_position,
				"path_length": path_length,
				"navigation_revision": _navigation.revision,
			}
	var best: Dictionary = {}
	for candidate in candidates.values():
		if best.is_empty() or candidate.path_length < best.path_length:
			best = candidate
	return best

func is_cover_valid(cover_position: Vector3, peek_position: Vector3, threat_position: Vector3) -> bool:
	_resolve_navigation()
	if _navigation == null:
		return false
	return (
		not _navigation.is_world_position_blocked(cover_position)
		and not _navigation.is_world_position_blocked(peek_position)
		and is_position_covered(cover_position, threat_position)
		and not is_position_covered(peek_position, threat_position)
	)

func is_position_covered(position: Vector3, threat_position: Vector3) -> bool:
	_resolve_navigation()
	var start := threat_position + Vector3.UP * body_height
	var end := position + Vector3.UP * body_height
	var excluded: Array[RID] = []
	for _attempt in 8:
		var query := PhysicsRayQueryParameters3D.create(start, end, occlusion_mask)
		query.exclude = excluded
		var hit := get_viewport().world_3d.direct_space_state.intersect_ray(query)
		if hit.is_empty():
			return false
		if _navigation == null or _navigation.is_world_position_blocked(hit.position):
			return true
		var collider := hit.get("collider") as CollisionObject3D
		if collider == null:
			return false
		excluded.append(collider.get_rid())
	return false

static func find_in_tree(node: Node) -> GameCoverService3D:
	if node == null or node.get_tree() == null:
		return null
	return node.get_tree().get_first_node_in_group("cover_service") as GameCoverService3D

func _find_peek_position(cover_cell: Vector2i, threat_position: Vector3, y: float) -> Vector3:
	var cover_position := _navigation.cell_to_world(cover_cell, y)
	var best_position := Vector3.INF
	var best_path_length := INF
	for vertical_offset in range(-2, 3):
		for horizontal_offset in range(-2, 3):
			if absi(horizontal_offset) + absi(vertical_offset) > 2:
				continue
			var candidate_cell := cover_cell + Vector2i(horizontal_offset, vertical_offset)
			if _navigation.is_cell_blocked(candidate_cell):
				continue
			var candidate := _navigation.cell_to_world(candidate_cell, y)
			if is_position_covered(candidate, threat_position):
				continue
			var path := _navigation.get_world_path(cover_position, candidate)
			if path.is_empty():
				continue
			var path_length := _navigation.get_world_path_length(path)
			if path_length < best_path_length:
				best_position = candidate
				best_path_length = path_length
	return best_position

func _resolve_navigation() -> void:
	if _navigation == null or not is_instance_valid(_navigation):
		_navigation = GameGridNavigation3D.find_in_tree(self)

func _planar_distance(first: Vector3, second: Vector3) -> float:
	var delta := first - second
	delta.y = 0.0
	return delta.length()
