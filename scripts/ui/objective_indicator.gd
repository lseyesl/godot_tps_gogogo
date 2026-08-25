class_name GameObjectiveIndicator
extends Control

@export var mission_path: NodePath
@export var player_path: NodePath
@export var camera_path: NodePath
@export_range(0.0, 200.0, 1.0) var screen_margin: float = 72.0

@onready var _mission: GameMissionController = get_node(mission_path) as GameMissionController
@onready var _player: PlayerCharacter = get_node(player_path) as PlayerCharacter
@onready var _camera: Camera3D = get_node(camera_path) as Camera3D
@onready var _marker: VBoxContainer = $Marker
@onready var _arrow: Label = $Marker/Arrow
@onready var _status: Label = $Marker/Status

func _process(_delta: float) -> void:
	var target := _mission.get_current_target()
	if target == null or _player == null or _camera == null:
		visible = false
		return
	visible = true
	var viewport_size := get_viewport_rect().size
	var center := viewport_size * 0.5
	var projected := _camera.unproject_position(target.global_position + Vector3.UP)
	var direction := projected - center
	if _camera.is_position_behind(target.global_position):
		direction = -direction
	if direction.length_squared() <= 0.01:
		direction = Vector2.UP
	var normalized_direction := direction.normalized()
	var horizontal_limit := maxf(1.0, center.x - screen_margin)
	var vertical_limit := maxf(1.0, center.y - screen_margin)
	var horizontal_scale := INF if is_zero_approx(normalized_direction.x) else horizontal_limit / absf(normalized_direction.x)
	var vertical_scale := INF if is_zero_approx(normalized_direction.y) else vertical_limit / absf(normalized_direction.y)
	var marker_position := center + normalized_direction * minf(horizontal_scale, vertical_scale)
	_marker.position = marker_position - _marker.size * 0.5
	_arrow.rotation = direction.angle() + PI * 0.5
	var distance := _planar_distance(_player.global_position, target.global_position)
	var objective_name := "任务" if _mission.current_phase == GameMissionController.MissionPhase.INFILTRATION else "撤离"
	_status.text = "%s · %s" % [objective_name, _mission.get_distance_band(distance)]

func _planar_distance(first: Vector3, second: Vector3) -> float:
	var delta := first - second
	delta.y = 0.0
	return delta.length()
