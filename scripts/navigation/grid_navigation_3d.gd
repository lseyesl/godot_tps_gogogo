class_name GameGridNavigation3D
extends Node

signal navigation_changed(revision: int)

@export var world_origin := Vector2(-30.0, -20.0)
@export var grid_size := Vector2i(30, 20)
@export var cell_size_meters: float = 2.0

var revision: int = 0
var _grid := AStarGrid2D.new()
var _obstacle_cells: Dictionary = {}
var _cell_block_counts: Dictionary = {}

func _ready() -> void:
	add_to_group("grid_navigation")
	_grid.region = Rect2i(Vector2i.ZERO, grid_size)
	_grid.cell_size = Vector2.ONE
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_grid.update()
	call_deferred("_register_scene_obstacles")

func register_obstacle(obstacle: Node3D) -> void:
	if obstacle == null or _obstacle_cells.has(obstacle.get_instance_id()):
		return
	var cells := _find_overlapping_cells(obstacle)
	_obstacle_cells[obstacle.get_instance_id()] = cells
	for cell in cells:
		var count: int = _cell_block_counts.get(cell, 0) + 1
		_cell_block_counts[cell] = count
		_grid.set_point_solid(cell, true)
	_bump_revision()

func unregister_obstacle(obstacle: Node3D) -> void:
	if obstacle == null:
		return
	var obstacle_id := obstacle.get_instance_id()
	if not _obstacle_cells.has(obstacle_id):
		return
	var cells: Array = _obstacle_cells[obstacle_id]
	_obstacle_cells.erase(obstacle_id)
	for cell in cells:
		var count: int = maxi(0, _cell_block_counts.get(cell, 0) - 1)
		if count == 0:
			_cell_block_counts.erase(cell)
			_grid.set_point_solid(cell, false)
		else:
			_cell_block_counts[cell] = count
	_bump_revision()

func get_world_path(from_position: Vector3, target_position: Vector3) -> PackedVector3Array:
	var from_cell := _nearest_open_cell(world_to_cell(from_position))
	var target_cell := _nearest_open_cell(world_to_cell(target_position))
	if from_cell.x < 0 or target_cell.x < 0:
		return PackedVector3Array()
	var id_path := _grid.get_id_path(from_cell, target_cell)
	var world_path := PackedVector3Array()
	for cell in id_path:
		world_path.append(cell_to_world(cell, from_position.y))
	if not world_path.is_empty() and not is_world_position_blocked(target_position):
		world_path.append(Vector3(target_position.x, from_position.y, target_position.z))
	return world_path

func world_to_cell(position: Vector3) -> Vector2i:
	return Vector2i(
		floori((position.x - world_origin.x) / cell_size_meters),
		floori((position.z - world_origin.y) / cell_size_meters)
	)

func cell_to_world(cell: Vector2i, y: float = 0.0) -> Vector3:
	return Vector3(
		world_origin.x + (cell.x + 0.5) * cell_size_meters,
		y,
		world_origin.y + (cell.y + 0.5) * cell_size_meters
	)

func is_cell_blocked(cell: Vector2i) -> bool:
	return not _grid.region.has_point(cell) or _grid.is_point_solid(cell)

func is_world_position_blocked(position: Vector3) -> bool:
	return is_cell_blocked(world_to_cell(position))

static func find_in_tree(node: Node) -> GameGridNavigation3D:
	if node == null or node.get_tree() == null:
		return null
	return node.get_tree().get_first_node_in_group("grid_navigation") as GameGridNavigation3D

func _register_scene_obstacles() -> void:
	for obstacle in get_tree().get_nodes_in_group("navigation_obstacles"):
		if obstacle is Node3D:
			register_obstacle(obstacle as Node3D)

func _find_overlapping_cells(obstacle: Node3D) -> Array[Vector2i]:
	var bounds := _get_obstacle_bounds(obstacle)
	var cells: Array[Vector2i] = []
	if bounds.size == Vector2.ZERO:
		return cells
	var half_cell := cell_size_meters * 0.5
	for y in grid_size.y:
		for x in grid_size.x:
			var cell := Vector2i(x, y)
			var center := cell_to_world(cell)
			var overlaps_x := center.x > bounds.position.x - half_cell + 0.001 and center.x < bounds.end.x + half_cell - 0.001
			var overlaps_z := center.z > bounds.position.y - half_cell + 0.001 and center.z < bounds.end.y + half_cell - 0.001
			if overlaps_x and overlaps_z:
				cells.append(cell)
	return cells

func _get_obstacle_bounds(obstacle: Node3D) -> Rect2:
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	var found_shape := false
	for child in obstacle.find_children("*", "CollisionShape3D", true, false):
		var collision_shape := child as CollisionShape3D
		if collision_shape == null or not collision_shape.shape is BoxShape3D:
			continue
		var box := collision_shape.shape as BoxShape3D
		var half := box.size * 0.5
		for x_sign in [-1.0, 1.0]:
			for z_sign in [-1.0, 1.0]:
				var corner := collision_shape.to_global(Vector3(half.x * x_sign, 0.0, half.z * z_sign))
				minimum = minimum.min(Vector2(corner.x, corner.z))
				maximum = maximum.max(Vector2(corner.x, corner.z))
				found_shape = true
	if not found_shape:
		return Rect2()
	return Rect2(minimum, maximum - minimum)

func _nearest_open_cell(origin: Vector2i) -> Vector2i:
	if _grid.region.has_point(origin) and not _grid.is_point_solid(origin):
		return origin
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for radius in range(1, 9):
		for y in range(origin.y - radius, origin.y + radius + 1):
			for x in range(origin.x - radius, origin.x + radius + 1):
				var candidate := Vector2i(x, y)
				if not _grid.region.has_point(candidate) or _grid.is_point_solid(candidate):
					continue
				var distance := Vector2(candidate - origin).length_squared()
				if distance < best_distance:
					best = candidate
					best_distance = distance
		if best.x >= 0:
			return best
	return best

func _bump_revision() -> void:
	revision += 1
	navigation_changed.emit(revision)
