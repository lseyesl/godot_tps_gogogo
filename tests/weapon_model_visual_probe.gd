extends SceneTree

const OUTPUT_PATH := "/tmp/gogogo-weapon-model-probe.png"
const MINIATURE_SCENES := [
	"res://scenes/visuals/player_miniature.tscn",
	"res://scenes/visuals/player_rifle_miniature.tscn",
	"res://scenes/visuals/player_rocket_miniature.tscn",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	for index in MINIATURE_SCENES.size():
		var packed := load(MINIATURE_SCENES[index]) as PackedScene
		if packed == null:
			_fail("miniature scene does not load: %s" % MINIATURE_SCENES[index])
			return
		var miniature := packed.instantiate() as Node3D
		miniature.position.x = (index - 1) * 1.55
		stage.add_child(miniature)

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.055, 0.065, 0.08)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.94, 0.94, 0.93)
	environment.ambient_light_energy = 1.6
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	stage.add_child(world_environment)

	var key_light := DirectionalLight3D.new()
	key_light.light_color = Color(0.93, 0.96, 1.0)
	key_light.light_energy = 1.15
	key_light.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	stage.add_child(key_light)

	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(0.0, 2.8, 6.5)
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.9, 0.0))
	camera.current = true
	for _frame in 8:
		await process_frame
	RenderingServer.force_sync()
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("viewport capture is empty")
		return
	image.save_png(OUTPUT_PATH)
	print("WEAPON_MODEL_PROBE path=%s" % OUTPUT_PATH)
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
