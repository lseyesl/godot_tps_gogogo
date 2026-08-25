class_name GameEnvironmentModule3D
extends StaticBody3D

var environment_active := true

func _ready() -> void:
	add_to_group("environment_modules")
	add_to_group("explosion_targets")
	add_to_group("navigation_obstacles")
	var navigation := GameGridNavigation3D.find_in_tree(self)
	if navigation != null:
		navigation.register_obstacle(self)

func is_environment_obstacle_active() -> bool:
	return environment_active

func deactivate_environment_module() -> void:
	if not environment_active:
		return
	environment_active = false
	remove_from_group("explosion_targets")
	remove_from_group("navigation_obstacles")
	var navigation := GameGridNavigation3D.find_in_tree(self)
	if navigation != null:
		navigation.unregister_obstacle(self)
	collision_layer = 0
	collision_mask = 0
	for child in find_children("*", "CollisionShape3D", true, false):
		var collision_shape := child as CollisionShape3D
		if collision_shape != null:
			collision_shape.disabled = true
	visible = false

func get_reaction_hub() -> GameEnvironmentReactionHub:
	return GameEnvironmentReactionHub.find_in_tree(self)
