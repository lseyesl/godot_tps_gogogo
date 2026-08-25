class_name AimLine3D
extends Node3D

@export var weapon_path: NodePath
@export var player_path: NodePath
@export_range(0.05, 1.0, 0.01) var segment_length: float = 0.28
@export_range(0.01, 1.0, 0.01) var segment_gap: float = 0.18
@export_range(1, 80, 1) var segment_count: int = 40
@export var idle_color := Color(0.35, 0.95, 0.78, 0.34)
@export var active_color := Color(0.4, 1.0, 0.82, 0.9)

var _segments: Array[MeshInstance3D] = []
var _material: StandardMaterial3D
var _active := false

@onready var _weapon: HitscanWeapon = get_node(weapon_path) as HitscanWeapon
@onready var _player: PlayerCharacter = get_node(player_path) as PlayerCharacter

func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = idle_color
	_material.emission_enabled = true
	_material.emission = idle_color
	for index in segment_count:
		var segment := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.035, 0.035, segment_length)
		box.material = _material
		segment.mesh = box
		segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(segment)
		_segments.append(segment)

func _process(_delta: float) -> void:
	if _weapon == null or _player == null:
		return
	var start := _weapon.global_position
	var endpoint := _weapon.get_aim_endpoint(_player.aim_direction)
	var total_length := start.distance_to(endpoint)
	var step := segment_length + segment_gap
	for index in _segments.size():
		var segment := _segments[index]
		var center_distance := float(index) * step + segment_length * 0.5
		segment.visible = center_distance <= total_length
		if segment.visible:
			segment.global_position = start + _player.aim_direction * center_distance
			segment.look_at(segment.global_position + _player.aim_direction, Vector3.UP)

func set_active(value: bool) -> void:
	if value == _active or _material == null:
		return
	_active = value
	var color := active_color if _active else idle_color
	_material.albedo_color = color
	_material.emission = color
