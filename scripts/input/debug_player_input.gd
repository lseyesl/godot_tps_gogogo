class_name DebugPlayerInput
extends Node

@export var player_path: NodePath
@export var camera_path: NodePath

@onready var _player: PlayerCharacter = get_node(player_path) as PlayerCharacter
@onready var _camera: Camera3D = get_node(camera_path) as Camera3D

func _ready() -> void:
	if OS.has_feature("mobile"):
		set_process(false)
		set_process_unhandled_input(false)
		return
	_ensure_action("move_left", KEY_A)
	_ensure_action("move_right", KEY_D)
	_ensure_action("move_up", KEY_W)
	_ensure_action("move_down", KEY_S)

func _process(_delta: float) -> void:
	if _player == null:
		return
	_player.set_move_input(Input.get_vector("move_left", "move_right", "move_up", "move_down"))
	_update_mouse_aim()

func _unhandled_input(event: InputEvent) -> void:
	if _player == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_player.request_fire()
		else:
			_player.release_fire()

func _update_mouse_aim() -> void:
	if _camera == null:
		return
	var mouse := get_viewport().get_mouse_position()
	var ray_origin := _camera.project_ray_origin(mouse)
	var ray_direction := _camera.project_ray_normal(mouse)
	var ground_plane := Plane(Vector3.UP, _player.global_position.y)
	var intersection: Variant = ground_plane.intersects_ray(ray_origin, ray_direction)
	if intersection is Vector3:
		var target := intersection as Vector3
		var delta := target - _player.global_position
		_player.set_aim_input(Vector2(delta.x, delta.z), true)

func _ensure_action(action_name: StringName, physical_key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.2)
	if not InputMap.action_get_events(action_name).is_empty():
		return
	var key_event := InputEventKey.new()
	key_event.physical_keycode = physical_key
	InputMap.action_add_event(action_name, key_event)
