class_name GameDamageFeedback3D
extends Node

@export var health_path: NodePath
@export var visual_root_path: NodePath
@export var show_screen_flash := false
@export var flash_seconds := 0.16
@export var enable_haptics := false
@export var enable_hit_reaction := false
@export_range(0.0, 0.3, 0.01) var reaction_distance := 0.14
@export_range(0, 100, 1) var hit_haptic_duration_ms := 40
@export_range(0.0, 1.0, 0.05) var hit_haptic_amplitude := 0.35

var hits_presented := 0
var _remaining := 0.0
var _meshes: Array[MeshInstance3D] = []
var _overlay: StandardMaterial3D
var _screen_flash: ColorRect
var _audio: AudioStreamPlayer3D
var _visual_root: Node3D
var _visual_rest_position := Vector3.ZERO
var _visual_rest_scale := Vector3.ONE

func _ready() -> void:
	var health := get_node(health_path) as HealthComponent
	health.damaged.connect(_on_damaged)
	_visual_root = get_node(visual_root_path) as Node3D
	_visual_rest_position = _visual_root.position
	_visual_rest_scale = _visual_root.scale
	for child in _visual_root.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(child as MeshInstance3D)
	_overlay = StandardMaterial3D.new()
	_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_overlay.albedo_color = Color(1.0, 0.92, 0.64, 0.9)
	_overlay.emission_enabled = true
	_overlay.emission = Color(1.0, 0.78, 0.34, 1.0)
	_overlay.emission_energy_multiplier = 2.4
	if show_screen_flash:
		_create_screen_flash()
	if DisplayServer.get_name() != "headless":
		_create_audio()

func _process(delta: float) -> void:
	_remaining = maxf(0.0, _remaining - delta)
	var active := _remaining > 0.0
	for mesh in _meshes:
		if is_instance_valid(mesh):
			mesh.material_overlay = _overlay if active else null
	if _screen_flash != null:
		_screen_flash.visible = active
		_screen_flash.modulate.a = clampf(_remaining / flash_seconds, 0.0, 1.0)
	if enable_hit_reaction and _visual_root != null:
		var recovery := 1.0 - exp(-24.0 * delta)
		_visual_root.position = _visual_root.position.lerp(_visual_rest_position, recovery)
		_visual_root.scale = _visual_root.scale.lerp(_visual_rest_scale, recovery)

func _on_damaged(_amount: float, source: Node) -> void:
	hits_presented += 1
	_remaining = flash_seconds
	_apply_hit_reaction(source)
	if _audio != null:
		_audio.pitch_scale = randf_range(0.92, 1.08)
		_audio.play()
	if enable_haptics and OS.has_feature("mobile") and hit_haptic_duration_ms > 0:
		Input.vibrate_handheld(hit_haptic_duration_ms, hit_haptic_amplitude)

func _apply_hit_reaction(source: Node) -> void:
	if not enable_hit_reaction or _visual_root == null:
		return
	var local_away := Vector3.BACK
	var actor := _visual_root.get_parent() as Node3D
	if source is Node3D and actor != null:
		var world_away := (actor.global_position - (source as Node3D).global_position)
		world_away.y = 0.0
		if world_away.length_squared() > 0.0001:
			local_away = actor.global_basis.inverse() * world_away.normalized()
	_visual_root.position = _visual_rest_position + local_away * reaction_distance
	_visual_root.scale = _visual_rest_scale * Vector3(1.06, 0.9, 1.06)

func _create_screen_flash() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	_screen_flash = ColorRect.new()
	_screen_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_flash.color = Color(0.75, 0.0, 0.0, 0.24)
	_screen_flash.visible = false
	layer.add_child(_screen_flash)

func _create_audio() -> void:
	_audio = AudioStreamPlayer3D.new()
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_8_BITS
	wave.mix_rate = 22050
	var sample_count := 2205
	var data := PackedByteArray()
	data.resize(sample_count)
	for index in sample_count:
		var envelope := 1.0 - float(index) / float(sample_count)
		var pulse := sin(float(index) * 0.08) * 0.55 + randf_range(-0.35, 0.35)
		data[index] = clampi(int(128.0 + pulse * envelope * 105.0), 0, 255)
	wave.data = data
	_audio.stream = wave
	add_child(_audio)
