class_name GameAimAssist3D
extends Node

signal lock_changed(target: PistolGuard)

@export var player_path: NodePath
@export var lock_indicator_path: NodePath
@export_range(0.0, 30.0, 0.1) var acquisition_angle_degrees: float = 10.0
@export_range(0.0, 60.0, 0.1) var release_angle_degrees: float = 18.0
@export_range(0.0, 1.0, 0.01) var occlusion_grace_seconds: float = 0.2

var locked_target: PistolGuard
var last_target: PistolGuard
var _occluded_elapsed := 0.0

@onready var _player: PlayerCharacter = get_node(player_path) as PlayerCharacter
@onready var _lock_indicator: Label3D = get_node_or_null(lock_indicator_path) as Label3D

func _ready() -> void:
	_update_lock_indicator(false)

func resolve_direction(raw_direction: Vector3, selection_active: bool = false, delta: float = 0.0) -> Vector3:
	var raw := raw_direction.normalized()
	if raw.length_squared() <= 0.0001:
		return Vector3.FORWARD
	if selection_active:
		_update_selection(raw)
	if locked_target == null:
		_update_lock_indicator(false)
		return raw
	if not _update_lock_validity(delta):
		return raw
	var target_direction := locked_target.global_position - _get_aim_origin()
	target_direction.y = 0.0
	if target_direction.length_squared() <= 0.0001:
		clear_lock()
		return raw
	_update_lock_indicator(is_zero_approx(_occluded_elapsed))
	return target_direction.normalized()

func has_lock() -> bool:
	return locked_target != null and is_instance_valid(locked_target)

func clear_lock() -> void:
	if locked_target == null:
		_update_lock_indicator(false)
		return
	locked_target = null
	last_target = null
	_occluded_elapsed = 0.0
	_update_lock_indicator(false)
	lock_changed.emit(null)

func _update_selection(raw_direction: Vector3) -> void:
	var candidate := _find_best_target(raw_direction)
	if candidate != null:
		_set_locked_target(candidate)
		return
	if locked_target == null or not is_instance_valid(locked_target):
		return
	var locked_direction := locked_target.global_position - _get_aim_origin()
	locked_direction.y = 0.0
	if locked_direction.length_squared() <= 0.0001 or raw_direction.angle_to(locked_direction.normalized()) > deg_to_rad(release_angle_degrees):
		clear_lock()

func _set_locked_target(target: PistolGuard) -> void:
	if target == locked_target:
		return
	locked_target = target
	last_target = target
	_occluded_elapsed = 0.0
	_update_lock_indicator(true)
	lock_changed.emit(locked_target)

func _update_lock_validity(delta: float) -> bool:
	if not is_instance_valid(locked_target) or locked_target.current_state == PistolGuard.GuardState.DEAD:
		clear_lock()
		return false
	if _player == null or _player.weapon == null or _player.weapon.definition == null or _player.vision == null:
		clear_lock()
		return false
	var target_position := locked_target.global_position + Vector3.UP * _player.vision.target_height
	var planar_delta := target_position - _get_aim_origin()
	planar_delta.y = 0.0
	if planar_delta.length() > _player.weapon.definition.range_meters or not _player.vision.is_position_in_view(target_position):
		clear_lock()
		return false
	if _player.vision.has_clear_line_to(locked_target):
		_occluded_elapsed = 0.0
		return true
	_occluded_elapsed += maxf(0.0, delta)
	_update_lock_indicator(false)
	if _occluded_elapsed >= occlusion_grace_seconds:
		clear_lock()
		return false
	return true

func _find_best_target(raw_direction: Vector3) -> PistolGuard:
	if _player == null or _player.vision == null or _player.weapon == null or _player.weapon.definition == null:
		return null
	var best: PistolGuard
	var best_angle := INF
	var best_distance := INF
	var maximum_angle := deg_to_rad(acquisition_angle_degrees)
	var origin := _get_aim_origin()
	for node in get_tree().get_nodes_in_group(&"guards"):
		if not node is PistolGuard:
			continue
		var guard := node as PistolGuard
		if guard.current_state == PistolGuard.GuardState.DEAD or not _player.vision.can_see(guard):
			continue
		var target_delta := guard.global_position - origin
		target_delta.y = 0.0
		var distance := target_delta.length()
		if distance <= 0.001 or distance > _player.weapon.definition.range_meters:
			continue
		var angle := raw_direction.angle_to(target_delta / distance)
		if angle > maximum_angle:
			continue
		if angle < best_angle - 0.0001 or (is_equal_approx(angle, best_angle) and distance < best_distance):
			best = guard
			best_angle = angle
			best_distance = distance
	return best

func _get_aim_origin() -> Vector3:
	if _player != null and _player.weapon != null:
		return _player.weapon.global_position
	return _player.global_position

func _update_lock_indicator(show: bool) -> void:
	if _lock_indicator == null:
		return
	_lock_indicator.visible = show and has_lock()
	if _lock_indicator.visible:
		_lock_indicator.global_position = locked_target.global_position + Vector3.UP * 2.15
