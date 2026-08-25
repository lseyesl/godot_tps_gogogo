class_name PlayerCharacter
extends CharacterBody3D

signal died

@export var move_speed: float = 4.5
@export var turn_speed_radians: float = 16.0
@export var footstep_interval_seconds: float = 0.45
@export var footstep_radius_meters: float = 4.0

var aim_direction := Vector3(0.0, 0.0, -1.0)
var _move_input := Vector2.ZERO
var _requested_aim := Vector2(0.0, -1.0)
var _footstep_timer := 0.0

@onready var health: HealthComponent = $HealthComponent
@onready var weapon: HitscanWeapon = $WeaponPivot/Muzzle/StandardPistol
@onready var aim_line: AimLine3D = $AimLine3D
@onready var vision: GameVisionSensor3D = $VisionSensor3D

func _ready() -> void:
	add_to_group("player")
	add_to_group("explosion_targets")
	add_to_group("fire_damage_targets")
	health.depleted.connect(_on_health_depleted)

func _physics_process(delta: float) -> void:
	velocity = Vector3(_move_input.x, 0.0, _move_input.y) * move_speed
	move_and_slide()
	_update_aim_direction()
	_update_footsteps(delta)

func set_move_input(value: Vector2) -> void:
	_move_input = value.limit_length(1.0)

func set_aim_input(value: Vector2, active: bool = true) -> void:
	if value.length_squared() > 0.01:
		_requested_aim = value.normalized()
	if aim_line != null:
		aim_line.set_active(active)

func request_fire() -> bool:
	if weapon == null:
		return false
	aim_line.set_active(true)
	return weapon.try_fire(aim_direction)

func release_fire() -> void:
	if aim_line != null:
		aim_line.set_active(false)

func apply_damage(amount: float, source: Node = null) -> float:
	return health.apply_damage(amount, source)

func _update_aim_direction() -> void:
	var desired := Vector3(_requested_aim.x, 0.0, _requested_aim.y).normalized()
	if desired.length_squared() <= 0.0001:
		return
	aim_direction = desired
	look_at(global_position + aim_direction, Vector3.UP)

func _on_health_depleted(_source: Node) -> void:
	set_physics_process(false)
	died.emit()

func _update_footsteps(delta: float) -> void:
	if _move_input.length_squared() <= 0.01:
		_footstep_timer = 0.0
		return
	_footstep_timer = maxf(0.0, _footstep_timer - delta)
	if not is_zero_approx(_footstep_timer):
		return
	var hub := GameSoundEventHub.find_in_tree(self)
	if hub != null:
		hub.emit_sound_event(
			global_position,
			footstep_radius_meters,
			GameSoundEventHub.Priority.FOOTSTEP,
			self
		)
	_footstep_timer = footstep_interval_seconds
