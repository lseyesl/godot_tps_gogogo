extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var instance := scene.instantiate() as Node3D
	root.add_child(instance)
	await process_frame
	await process_frame
	var navigation := instance.get_node("GridNavigation3D") as GameGridNavigation3D
	var player := instance.get_node("Player") as PlayerCharacter
	player.set_physics_process(false)
	for guard_node in get_nodes_in_group("guards"):
		if instance.is_ancestor_of(guard_node):
			(guard_node as PistolGuard).set_physics_process(false)
	print("Legend: # blocked, . unreachable, o reachable, P player")
	var player_cell := navigation.world_to_cell(player.global_position)
	for y in navigation.grid_size.y:
		var row := ""
		for x in navigation.grid_size.x:
			var cell := Vector2i(x, y)
			if cell == player_cell:
				row += "P"
			elif navigation.is_cell_blocked(cell):
				row += "#"
			elif navigation.get_world_path(player.global_position, navigation.cell_to_world(cell)).is_empty():
				row += "."
			else:
				row += "o"
		print("%02d %s" % [y, row])
	for container_name in ["GuardCandidates", "ObjectiveCandidates", "WeaponCandidates", "HealthCandidates"]:
		var container := instance.get_node("ContentCandidates/%s" % container_name)
		for child_node in container.get_children():
			var marker := child_node as Marker3D
			var cell := navigation.world_to_cell(marker.global_position)
			print("%s/%s cell=%s blocked=%s path=%d" % [
				container_name,
				marker.name,
				cell,
				navigation.is_cell_blocked(cell),
				navigation.get_world_path(player.global_position, marker.global_position).size(),
			])
	instance.queue_free()
	await process_frame
	quit()
