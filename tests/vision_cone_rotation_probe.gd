extends SceneTree

const START_ANGLE_DEGREES := -35.0
const END_ANGLE_DEGREES := 35.0
const ROTATION_STEP_DEGREES := 0.1
const FIELD_OF_VIEW_DEGREES := 120.0
const MAXIMUM_CONTINUOUS_AREA_STEP := 1.0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var minimal := "--minimal" in OS.get_cmdline_user_args()
	var player: PlayerCharacter
	if minimal:
		player = _build_minimal_wall_scenario()
	else:
		var packed := load("res://scenes/main/main.tscn") as PackedScene
		var instance := packed.instantiate() as Node3D
		root.add_child(instance)
		var debug_input := instance.get_node("DebugPlayerInput")
		debug_input.set_process(false)
		debug_input.set_process_unhandled_input(false)
		player = instance.get_node("Player") as PlayerCharacter
	await process_frame
	await physics_frame
	var configured_ray_count := (player.get_node("VisionCone3D") as GameVisionCone3D).ray_count
	var requested_ray_count := _get_requested_ray_count()
	var ray_count := requested_ray_count if requested_ray_count > 0 else configured_ray_count
	player.set_physics_process(false)
	player.global_position = Vector3(0.0, 0.0, 5.0)
	var previous_area := -1.0
	var maximum_area_step := 0.0
	var maximum_step_angle := 0.0
	var sample_count := roundi((END_ANGLE_DEGREES - START_ANGLE_DEGREES) / ROTATION_STEP_DEGREES) + 1
	for sample_index in sample_count:
		var heading := START_ANGLE_DEGREES + float(sample_index) * ROTATION_STEP_DEGREES
		player.rotation.y = deg_to_rad(heading)
		var area := _get_visibility_area(player, ray_count)
		if previous_area >= 0.0:
			var area_step := absf(area - previous_area)
			if area_step > maximum_area_step:
				maximum_area_step = area_step
				maximum_step_angle = heading
		previous_area = area
	print("VISION_CONE_ROTATION_PROBE minimal=%s rays=%d max_area_step=%.4f at_heading=%.2f samples=%d" % [
		minimal,
		ray_count,
		maximum_area_step,
		maximum_step_angle,
		sample_count,
	])
	if maximum_area_step > MAXIMUM_CONTINUOUS_AREA_STEP:
		push_error("occluded vision boundary jumps while rotating: %.4f square meters" % maximum_area_step)
		quit(1)
		return
	print("PASS: occluded vision boundary changes continuously while rotating")
	quit(0)

func _build_minimal_wall_scenario() -> PlayerCharacter:
	var world := Node3D.new()
	root.add_child(world)
	var player_scene := load("res://scenes/actors/player.tscn") as PackedScene
	var player := player_scene.instantiate() as PlayerCharacter
	world.add_child(player)
	var wall := StaticBody3D.new()
	wall.collision_layer = 2
	wall.position = Vector3(0.0, 0.0, -3.0)
	var collision := CollisionShape3D.new()
	collision.position.y = 0.6
	var box := BoxShape3D.new()
	box.size = Vector3(8.0, 1.2, 0.4)
	collision.shape = box
	wall.add_child(collision)
	world.add_child(wall)
	return player

func _get_requested_ray_count() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--rays="):
			return maxi(4, int(argument.trim_prefix("--rays=")))
	return -1

func _get_visibility_area(player: PlayerCharacter, ray_count: int) -> float:
	var distances := PackedFloat32Array()
	for ray_index in range(ray_count + 1):
		var angle := lerpf(
			-FIELD_OF_VIEW_DEGREES * 0.5,
			FIELD_OF_VIEW_DEGREES * 0.5,
			float(ray_index) / float(ray_count)
		)
		var local_direction := Vector3(sin(deg_to_rad(angle)), 0.0, -cos(deg_to_rad(angle)))
		var world_direction := (player.global_basis * local_direction).normalized()
		distances.append(player.vision.get_occluded_distance(world_direction))
	var ray_step_radians := deg_to_rad(FIELD_OF_VIEW_DEGREES / float(ray_count))
	var area := 0.0
	for index in ray_count:
		area += 0.5 * distances[index] * distances[index + 1] * sin(ray_step_radians)
	return area
