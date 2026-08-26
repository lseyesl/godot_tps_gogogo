class_name GameShotFeedback3D
extends Node3D

@export var weapon_pivot_path: NodePath
@export var flash_seconds := 0.07
@export var tracer_seconds := 0.06
@export var hit_seconds := 0.1
@export var recoil_distance := 0.14

var shots_presented := 0
var _flash_remaining := 0.0
var _tracer_remaining := 0.0
var _hit_remaining := 0.0
var _weapon: GameWeapon3D
var _pivot: Node3D
var _pivot_rest := Vector3.ZERO
var _flash: MeshInstance3D
var _tracer: MeshInstance3D
var _impact: MeshInstance3D
var _audio: AudioStreamPlayer3D

func _ready() -> void:
	_pivot = get_node_or_null(weapon_pivot_path) as Node3D
	if _pivot != null:
		_pivot_rest = _pivot.position
	_create_visuals()
	if DisplayServer.get_name() != "headless":
		_create_audio()

func bind_weapon(value: GameWeapon3D) -> void:
	if _weapon != null and _weapon.fired.is_connected(_on_weapon_fired):
		_weapon.fired.disconnect(_on_weapon_fired)
	_weapon = value
	if _weapon != null and not _weapon.fired.is_connected(_on_weapon_fired):
		_weapon.fired.connect(_on_weapon_fired)

func _process(delta: float) -> void:
	_flash_remaining = maxf(0.0, _flash_remaining - delta)
	_tracer_remaining = maxf(0.0, _tracer_remaining - delta)
	_hit_remaining = maxf(0.0, _hit_remaining - delta)
	_flash.visible = _flash_remaining > 0.0
	_tracer.visible = _tracer_remaining > 0.0
	_impact.visible = _hit_remaining > 0.0
	if _pivot != null:
		_pivot.position = _pivot.position.lerp(_pivot_rest, minf(1.0, delta * 22.0))

func _on_weapon_fired(origin: Vector3, endpoint: Vector3, hit: bool) -> void:
	shots_presented += 1
	_flash_remaining = flash_seconds
	_tracer_remaining = tracer_seconds
	_hit_remaining = hit_seconds if hit else 0.0
	_flash.global_position = origin
	var distance := origin.distance_to(endpoint)
	_tracer.global_position = origin.lerp(endpoint, 0.5)
	_tracer.scale = Vector3(1.0, 1.0, maxf(0.01, distance))
	_tracer.look_at(endpoint, Vector3.UP)
	_impact.global_position = endpoint
	if _pivot != null:
		_pivot.position = _pivot_rest + Vector3(0.0, 0.0, recoil_distance)
	if _audio != null:
		_audio.pitch_scale = randf_range(0.94, 1.06)
		_audio.play()
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(30)

func _create_visuals() -> void:
	var flash_material := _emissive_material(Color(1.0, 0.72, 0.18, 0.95))
	_flash = MeshInstance3D.new()
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.16
	flash_mesh.height = 0.32
	flash_mesh.material = flash_material
	_flash.mesh = flash_mesh
	_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_flash)

	_tracer = MeshInstance3D.new()
	var tracer_mesh := BoxMesh.new()
	tracer_mesh.size = Vector3(0.035, 0.035, 1.0)
	tracer_mesh.material = _emissive_material(Color(1.0, 0.82, 0.3, 0.9))
	_tracer.mesh = tracer_mesh
	_tracer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_tracer)

	_impact = MeshInstance3D.new()
	var impact_mesh := SphereMesh.new()
	impact_mesh.radius = 0.11
	impact_mesh.height = 0.22
	impact_mesh.material = _emissive_material(Color(1.0, 0.22, 0.08, 0.95))
	_impact.mesh = impact_mesh
	_impact.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_impact)
	_flash.visible = false
	_tracer.visible = false
	_impact.visible = false

func _create_audio() -> void:
	_audio = AudioStreamPlayer3D.new()
	_audio.max_distance = 28.0
	_audio.unit_size = 6.0
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_8_BITS
	wave.mix_rate = 22050
	wave.stereo = false
	var sample_count := 1543
	var data := PackedByteArray()
	data.resize(sample_count)
	for index in sample_count:
		var envelope := 1.0 - float(index) / float(sample_count)
		var noise := randf_range(-1.0, 1.0)
		var tone := sin(float(index) * 0.19) * 0.45
		data[index] = clampi(int(128.0 + (noise * 0.55 + tone) * envelope * 110.0), 0, 255)
	wave.data = data
	_audio.stream = wave
	add_child(_audio)

func _emissive_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	return material
