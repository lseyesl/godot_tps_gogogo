class_name GameBrickWallLine3D
extends StaticBody3D

const MODULE_LENGTH_METERS := 2.0
const WALL_HEIGHT_METERS := 1.2
const WALL_THICKNESS_METERS := 0.4
const BRICK_WALL_VISUAL := preload("res://scenes/visuals/environment/brick_wall_visual.tscn")

@export_range(2.0, 100.0, 2.0) var length_meters: float = 2.0
@export var along_z: bool = false
@export var blocks_navigation: bool = false

func _ready() -> void:
	if blocks_navigation:
		add_to_group("navigation_obstacles")
	_build_collision()
	_build_visuals()

func get_module_count() -> int:
	return roundi(length_meters / MODULE_LENGTH_METERS)

func _build_collision() -> void:
	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	collision_shape.position.y = WALL_HEIGHT_METERS * 0.5
	var box := BoxShape3D.new()
	box.size = Vector3(
		WALL_THICKNESS_METERS if along_z else length_meters,
		WALL_HEIGHT_METERS,
		length_meters if along_z else WALL_THICKNESS_METERS
	)
	collision_shape.shape = box
	add_child(collision_shape)

func _build_visuals() -> void:
	var visual_root := Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)
	var module_count := get_module_count()
	var first_offset := -length_meters * 0.5 + MODULE_LENGTH_METERS * 0.5
	for index in module_count:
		var module := BRICK_WALL_VISUAL.instantiate() as Node3D
		module.name = "Module%02d" % (index + 1)
		var offset := first_offset + index * MODULE_LENGTH_METERS
		module.position = Vector3(0.0, 0.0, offset) if along_z else Vector3(offset, 0.0, 0.0)
		if along_z:
			module.rotation.y = PI * 0.5
		visual_root.add_child(module)
