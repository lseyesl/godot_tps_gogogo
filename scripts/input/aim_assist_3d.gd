class_name GameAimAssist3D
extends Node

@export var player_path: NodePath
@export_range(0.0, 30.0, 0.1) var candidate_angle_degrees: float = 10.0
@export_range(0.0, 1.0, 0.01) var correction_strength: float = 0.4
@export_range(0.0, 10.0, 0.1) var maximum_correction_degrees: float = 3.0

var last_target: PistolGuard

@onready var _player: PlayerCharacter = get_node(player_path) as PlayerCharacter

func resolve_direction(raw_direction: Vector3) -> Vector3:
	var raw := raw_direction.normalized()
	last_target = _find_best_target(raw)
	if last_target == null:
		return raw
	var target_direction := last_target.global_position - _get_aim_origin()
	target_direction.y = 0.0
	target_direction = target_direction.normalized()
	var angle := raw.angle_to(target_direction)
	if angle <= 0.0001:
		return target_direction
	var maximum_correction := deg_to_rad(maximum_correction_degrees)
	var weight := minf(correction_strength, maximum_correction / angle)
	return raw.slerp(target_direction, weight).normalized()

func _find_best_target(raw_direction: Vector3) -> PistolGuard:
	if _player == null or _player.vision == null:
		return null
	var best: PistolGuard
	var best_angle := INF
	var best_distance := INF
	var maximum_angle := deg_to_rad(candidate_angle_degrees)
	var origin := _get_aim_origin()
	for node in get_tree().get_nodes_in_group(&"guards"):
		if not node is PistolGuard:
			continue
		var guard := node as PistolGuard
		if guard.current_state == PistolGuard.GuardState.DEAD or not _player.vision.can_see(guard):
			continue
		var delta := guard.global_position - origin
		delta.y = 0.0
		var distance := delta.length()
		if distance <= 0.001 or distance > _player.vision.view_distance:
			continue
		var angle := raw_direction.angle_to(delta / distance)
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
