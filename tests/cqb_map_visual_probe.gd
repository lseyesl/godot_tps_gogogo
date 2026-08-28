extends SceneTree

const OUTPUT_PATH := "/tmp/gogogo-cqb-room-layout.png"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene does not load")
		return
	var instance := packed.instantiate()
	root.add_child(instance)
	for _frame in 8:
		await process_frame
	for _frame in 4:
		await physics_frame
	var debug_input := instance.get_node_or_null("DebugPlayerInput")
	if debug_input != null:
		debug_input.set_process(false)
		debug_input.set_process_unhandled_input(false)
	var original_camera := instance.get_node_or_null("Camera3D") as Camera3D
	if original_camera != null:
		original_camera.current = false
		original_camera.set_process(false)
	var hud := instance.get_node_or_null("HUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	var player := instance.get_node_or_null("Player") as Node3D
	if player != null:
		player.visible = false
		player.set_physics_process(false)
	for guard_node in get_nodes_in_group("guards"):
		var guard := guard_node as Node3D
		if guard != null and instance.is_ancestor_of(guard):
			guard.visible = false
			guard.set_physics_process(false)
	var camera := Camera3D.new()
	camera.name = "CQBMapProbeCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 44.0
	camera.position = Vector3(0.0, 55.0, 0.0)
	camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	instance.add_child(camera)
	camera.current = true
	for _frame in 8:
		await process_frame
	RenderingServer.force_sync()
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("viewport capture is empty")
		return
	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		_fail("could not save map capture: %s" % error_string(error))
		return
	print("CQB_MAP_PROBE path=%s size=%s" % [OUTPUT_PATH, image.get_size()])
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
