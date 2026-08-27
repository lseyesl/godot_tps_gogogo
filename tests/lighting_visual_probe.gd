extends SceneTree

const OUTPUT_PATH := "/tmp/gogogo-lighting-probe.png"
const MIN_MEAN_LUMINANCE := 0.27
const MAX_MEAN_LUMINANCE := 0.72
const MIN_LOCAL_CONTRAST := 0.03

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
	var player := instance.get_node_or_null("Player") as PlayerCharacter
	var camera := instance.get_node_or_null("Camera3D") as Camera3D
	var wall_mesh := instance.get_node_or_null("WoodWallB/WoodenWallVisual/Model/world/geometry_0") as MeshInstance3D
	var visibility := instance.get_node_or_null("WorldVisibility3D") as GameWorldVisibility3D
	if player == null or camera == null or wall_mesh == null or visibility == null:
		_fail("lighting probe nodes are missing")
		return
	player.set_physics_process(false)
	player.global_position = Vector3(0.0, 0.0, 5.0)
	player.rotation = Vector3.ZERO
	visibility.set_process(false)
	visibility.update_visibility_now()
	for _frame in 8:
		await process_frame
	visibility.update_visibility_now()
	RenderingServer.force_sync()
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("viewport capture is empty")
		return
	image.save_png(OUTPUT_PATH)
	var rect := _screen_rect_for_mesh(camera, wall_mesh, image.get_size())
	if rect.size.x < 4 or rect.size.y < 4:
		_fail("target wall is not measurable on screen: %s" % rect)
		return
	var metrics := _measure(image, rect)
	print("LIGHTING_PROBE path=%s rect=%s mean=%.4f contrast=%.4f" % [OUTPUT_PATH, rect, metrics.mean, metrics.contrast])
	if metrics.mean < MIN_MEAN_LUMINANCE or metrics.mean > MAX_MEAN_LUMINANCE or metrics.contrast < MIN_LOCAL_CONTRAST:
		_fail("visible wall lacks readable brightness/detail (mean %.4f, contrast %.4f)" % [metrics.mean, metrics.contrast])
		return
	print("PASS: visible wall lighting detail")
	quit(0)

func _screen_rect_for_mesh(camera: Camera3D, mesh_instance: MeshInstance3D, image_size: Vector2i) -> Rect2i:
	var bounds := mesh_instance.get_aabb()
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for x in [bounds.position.x, bounds.end.x]:
		for y in [bounds.position.y, bounds.end.y]:
			for z in [bounds.position.z, bounds.end.z]:
				var world := mesh_instance.global_transform * Vector3(x, y, z)
				if camera.is_position_behind(world):
					continue
				var point := camera.unproject_position(world)
				minimum = minimum.min(point)
				maximum = maximum.max(point)
	if is_inf(minimum.x):
		return Rect2i()
	var left := clampi(floori(minimum.x), 0, image_size.x - 1)
	var top := clampi(floori(minimum.y), 0, image_size.y - 1)
	var right := clampi(ceili(maximum.x), left + 1, image_size.x)
	var bottom := clampi(ceili(maximum.y), top + 1, image_size.y)
	return Rect2i(left, top, right - left, bottom - top)

func _measure(image: Image, rect: Rect2i) -> Dictionary:
	var luminances: Array[float] = []
	var luminance_sum := 0.0
	var gradient_sum := 0.0
	var gradient_count := 0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var value := image.get_pixel(x, y).get_luminance()
			luminances.append(value)
			luminance_sum += value
			if x > rect.position.x:
				gradient_sum += absf(value - image.get_pixel(x - 1, y).get_luminance())
				gradient_count += 1
			if y > rect.position.y:
				gradient_sum += absf(value - image.get_pixel(x, y - 1).get_luminance())
				gradient_count += 1
	var mean := luminance_sum / maxf(1.0, float(luminances.size()))
	var variance := 0.0
	for value in luminances:
		variance += (value - mean) * (value - mean)
	var deviation := sqrt(variance / maxf(1.0, float(luminances.size())))
	var gradient := gradient_sum / maxf(1.0, float(gradient_count))
	return {"mean": mean, "contrast": maxf(deviation, gradient * 2.0)}

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
