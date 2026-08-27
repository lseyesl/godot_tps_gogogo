extends SceneTree

const VISIBLE_PATH := "/tmp/gogogo-vision-cone-visible.png"
const HIDDEN_PATH := "/tmp/gogogo-vision-cone-hidden.png"
const MINIMUM_SAMPLE_DIFFERENCE := 0.012

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var hide_floor := "--hide-floor" in OS.get_cmdline_user_args()
	root.size = Vector2i(1280, 720)
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene does not load")
		return
	var instance := packed.instantiate() as Node3D
	root.add_child(instance)
	for _frame in 12:
		await process_frame
	for _frame in 4:
		await physics_frame

	var debug_input := instance.get_node("DebugPlayerInput")
	debug_input.set_process(false)
	debug_input.set_process_unhandled_input(false)
	var player := instance.get_node("Player") as PlayerCharacter
	var camera := instance.get_node("Camera3D") as FixedFollowCamera
	var cone := player.get_node("VisionCone3D") as GameVisionCone3D
	var floor := instance.get_node("Floor") as MeshInstance3D
	player.set_physics_process(false)
	player.global_position = Vector3(0.0, 0.0, 5.0)
	player.rotation = Vector3.ZERO
	player.set_aim_input(Vector2(0.0, -1.0), true)
	player.call("_update_aim_direction")
	cone.call("_rebuild_cone")
	if hide_floor:
		floor.visible = false
	for node in instance.get_tree().get_nodes_in_group("guards"):
		(node as PistolGuard).set_physics_process(false)
	for _frame in 4:
		await process_frame
	RenderingServer.force_sync()
	var visible_image := root.get_texture().get_image()
	visible_image.save_png(VISIBLE_PATH)

	cone.visible = false
	await process_frame
	await process_frame
	RenderingServer.force_sync()
	var hidden_image := root.get_texture().get_image()
	hidden_image.save_png(HIDDEN_PATH)

	var sample_offsets := [
		Vector3(-0.7, 0.035, -2.0),
		Vector3(0.0, 0.035, -2.0),
		Vector3(0.7, 0.035, -2.0),
		Vector3(-1.4, 0.035, -4.0),
		Vector3(0.0, 0.035, -4.0),
		Vector3(1.4, 0.035, -4.0),
		Vector3(-2.0, 0.035, -6.0),
		Vector3(0.0, 0.035, -6.0),
		Vector3(2.0, 0.035, -6.0),
	]
	var visible_samples := 0
	var differences := PackedFloat32Array()
	for offset in sample_offsets:
		var screen_position := camera.unproject_position(player.global_position + offset)
		var difference := _sample_difference(visible_image, hidden_image, screen_position)
		differences.append(difference)
		if difference >= MINIMUM_SAMPLE_DIFFERENCE:
			visible_samples += 1
	print("VISION_CONE_PROBE hide_floor=%s visible_samples=%d/%d differences=%s visible=%s hidden=%s" % [
		hide_floor,
		visible_samples,
		sample_offsets.size(),
		differences,
		VISIBLE_PATH,
		HIDDEN_PATH,
	])
	if visible_samples < sample_offsets.size():
		_fail("screen-up vision cone is covered or missing at one or more ground samples")
		return
	print("PASS: screen-up vision cone is visible throughout the main scene")
	quit(0)

func _sample_difference(first: Image, second: Image, center: Vector2) -> float:
	var total := 0.0
	var count := 0
	for y_offset in range(-2, 3):
		for x_offset in range(-2, 3):
			var x := clampi(roundi(center.x) + x_offset, 0, first.get_width() - 1)
			var y := clampi(roundi(center.y) + y_offset, 0, first.get_height() - 1)
			var left := first.get_pixel(x, y)
			var right := second.get_pixel(x, y)
			total += (absf(left.r - right.r) + absf(left.g - right.g) + absf(left.b - right.b)) / 3.0
			count += 1
	return total / float(count)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
