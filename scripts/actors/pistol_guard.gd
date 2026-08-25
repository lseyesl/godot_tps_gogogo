class_name PistolGuard
extends CharacterBody3D

signal state_changed(previous: int, current: int)
signal warning_started(guard: PistolGuard)
signal attack_exposed(guard: PistolGuard, duration: float)
signal died(guard: PistolGuard)

enum GuardState {
	PATROL,
	WARNING,
	COMBAT,
	INVESTIGATE,
	SEARCH,
	DEAD,
}

@export var patrol_turn_speed: float = 0.55
@export var search_speed: float = 3.2
@export var warning_seconds: float = 0.6
@export var shot_direction_lock_seconds: float = 0.2
@export var lost_sight_grace_seconds: float = 0.35
@export var search_seconds: float = 3.0
@export var attack_exposure_seconds: float = 2.0

var current_state := GuardState.PATROL
var exposure_remaining: float = 0.0

var _player: PlayerCharacter
var _state_timer: float = 0.0
var _shot_timer: float = 0.0
var _aim_lock_remaining: float = 0.0
var _lost_sight_time: float = 0.0
var _locked_shot_direction := Vector3.FORWARD
var _last_known_player_position := Vector3.ZERO
var _last_exposed_position := Vector3.ZERO
var _exposure_was_visible := false
var _active_sound_priority: int = 0

@onready var health: HealthComponent = $HealthComponent
@onready var weapon: HitscanWeapon = $VisualRoot/WeaponPivot/Muzzle/StandardPistol
@onready var vision: GameVisionSensor3D = $VisionSensor3D
@onready var visual_root: Node3D = $VisualRoot
@onready var warning_indicator: Label3D = $VisualRoot/WarningIndicator
@onready var last_position_marker: MeshInstance3D = $LastExposedPositionMarker

func _ready() -> void:
	add_to_group("guards")
	health.damaged.connect(_on_damaged)
	health.depleted.connect(_on_depleted)
	var sound_hub := GameSoundEventHub.find_in_tree(self)
	if sound_hub != null:
		sound_hub.sound_emitted.connect(_on_sound_emitted)
	last_position_marker.top_level = true
	last_position_marker.visible = false
	_resolve_player()

func _physics_process(delta: float) -> void:
	if current_state == GuardState.DEAD:
		return
	if _player == null or not is_instance_valid(_player):
		_resolve_player()
		return
	exposure_remaining = maxf(0.0, exposure_remaining - delta)
	match current_state:
		GuardState.PATROL:
			_process_patrol(delta)
		GuardState.WARNING:
			_process_warning(delta)
		GuardState.COMBAT:
			_process_combat(delta)
		GuardState.INVESTIGATE:
			_process_investigate(delta)
		GuardState.SEARCH:
			_process_search(delta)
	_update_player_visibility()

func apply_damage(amount: float, source: Node = null) -> float:
	return health.apply_damage(amount, source)

func can_see_player() -> bool:
	return _player != null and vision.can_see(_player)

func _process_patrol(delta: float) -> void:
	velocity = Vector3.ZERO
	rotate_y(patrol_turn_speed * delta)
	if can_see_player():
		_begin_warning()

func _process_warning(delta: float) -> void:
	velocity = Vector3.ZERO
	_state_timer = maxf(0.0, _state_timer - delta)
	if can_see_player():
		_last_known_player_position = _player.global_position
	if _state_timer > shot_direction_lock_seconds:
		_face_position(_last_known_player_position)
		_locked_shot_direction = _direction_to(_last_known_player_position)
	if is_zero_approx(_state_timer):
		_fire_locked_shot()
		_transition_to(GuardState.COMBAT)
		_shot_timer = weapon.definition.shot_interval_seconds

func _process_combat(delta: float) -> void:
	velocity = Vector3.ZERO
	var sees_player := can_see_player()
	if sees_player:
		_lost_sight_time = 0.0
		_last_known_player_position = _player.global_position
	else:
		_lost_sight_time += delta
		if _lost_sight_time >= lost_sight_grace_seconds:
			_begin_search()
			return
	_shot_timer = maxf(0.0, _shot_timer - delta)
	if _aim_lock_remaining > 0.0:
		_aim_lock_remaining = maxf(0.0, _aim_lock_remaining - delta)
		if is_zero_approx(_aim_lock_remaining):
			_fire_locked_shot()
			_shot_timer = weapon.definition.shot_interval_seconds
		return
	if sees_player:
		_face_position(_last_known_player_position)
		if is_zero_approx(_shot_timer) and weapon.can_fire():
			_locked_shot_direction = _direction_to(_last_known_player_position)
			_aim_lock_remaining = shot_direction_lock_seconds

func _process_search(delta: float) -> void:
	var planar_delta := _last_known_player_position - global_position
	planar_delta.y = 0.0
	if planar_delta.length() > 0.45:
		velocity = planar_delta.normalized() * search_speed
		_face_position(_last_known_player_position)
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		rotate_y(patrol_turn_speed * delta)
		_state_timer = maxf(0.0, _state_timer - delta)
	if can_see_player():
		_begin_warning()
	elif is_zero_approx(_state_timer):
		_transition_to(GuardState.PATROL)

func _process_investigate(delta: float) -> void:
	var planar_delta := _last_known_player_position - global_position
	planar_delta.y = 0.0
	if planar_delta.length() > 0.45:
		velocity = planar_delta.normalized() * search_speed
		_face_position(_last_known_player_position)
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		rotate_y(patrol_turn_speed * delta)
		_state_timer = maxf(0.0, _state_timer - delta)
	if can_see_player():
		_active_sound_priority = 0
		_begin_warning()
	elif is_zero_approx(_state_timer):
		_active_sound_priority = 0
		_transition_to(GuardState.PATROL)

func _begin_warning() -> void:
	_last_known_player_position = _player.global_position
	_locked_shot_direction = _direction_to(_last_known_player_position)
	_state_timer = warning_seconds
	warning_indicator.visible = true
	_transition_to(GuardState.WARNING)
	warning_started.emit(self)

func _begin_search() -> void:
	_state_timer = search_seconds
	_aim_lock_remaining = 0.0
	warning_indicator.visible = false
	_transition_to(GuardState.SEARCH)

func _fire_locked_shot() -> void:
	warning_indicator.visible = false
	if not weapon.try_fire(_locked_shot_direction):
		return
	exposure_remaining = attack_exposure_seconds
	_last_exposed_position = global_position
	_exposure_was_visible = true
	attack_exposed.emit(self, exposure_remaining)

func _update_player_visibility() -> void:
	if _player == null or _player.vision == null:
		visual_root.visible = true
		last_position_marker.visible = false
		return
	var visible_in_cone := _player.vision.can_see(self)
	var exposed_with_clear_line := (
		exposure_remaining > 0.0
		and _player.vision.has_clear_line_to(self)
	)
	visual_root.visible = visible_in_cone or exposed_with_clear_line
	if exposed_with_clear_line:
		_last_exposed_position = global_position
		_exposure_was_visible = true
		last_position_marker.visible = false
	elif exposure_remaining > 0.0 and _exposure_was_visible:
		last_position_marker.global_position = _last_exposed_position + Vector3.UP * 0.04
		last_position_marker.visible = true
	else:
		last_position_marker.visible = false
		if exposure_remaining <= 0.0:
			_exposure_was_visible = false

func _face_position(target_position: Vector3) -> void:
	var target := target_position
	target.y = global_position.y
	if global_position.distance_squared_to(target) > 0.001:
		look_at(target, Vector3.UP)

func _direction_to(target_position: Vector3) -> Vector3:
	var direction := target_position + Vector3.UP * 0.9 - weapon.global_position
	return direction.normalized()

func _transition_to(next_state: int) -> void:
	if current_state == next_state:
		return
	var previous := current_state
	current_state = next_state
	state_changed.emit(previous, current_state)

func _resolve_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as PlayerCharacter

func _on_damaged(_amount: float, source: Node) -> void:
	if source is PlayerCharacter:
		_player = source as PlayerCharacter
		_last_known_player_position = _player.global_position
		if current_state == GuardState.PATROL or current_state == GuardState.SEARCH:
			_begin_warning()

func _on_depleted(_source: Node) -> void:
	_transition_to(GuardState.DEAD)
	visual_root.visible = true
	last_position_marker.visible = false
	set_physics_process(false)
	died.emit(self)
	queue_free()

func _on_sound_emitted(position: Vector3, radius: float, priority: int, source: Node) -> void:
	if current_state == GuardState.DEAD or source == self:
		return
	if global_position.distance_to(position) > radius:
		return
	if current_state == GuardState.WARNING or current_state == GuardState.COMBAT:
		return
	if current_state == GuardState.INVESTIGATE and priority < _active_sound_priority:
		return
	_active_sound_priority = priority
	_last_known_player_position = position
	_state_timer = 2.0
	_transition_to(GuardState.INVESTIGATE)
