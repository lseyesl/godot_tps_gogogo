class_name GameWeapon3D
extends Marker3D

signal fired(origin: Vector3, endpoint: Vector3, hit: bool)
signal damage_confirmed(target: Object, position: Vector3, amount: float)
signal ammo_changed(in_magazine: int, magazine_capacity: int)
signal reserve_changed(reserve: int, maximum: int)
signal reload_started(duration: float)
signal reload_finished
signal out_of_ammo

@export var definition: WeaponDefinition
@export var owner_body_path: NodePath

var initial_magazine: int = -1
var initial_reserve_ammo: int = -2
var ammo_in_magazine: int = 0
var reserve_ammo: int = 0
var current_spread_degrees: float = 0.0

var _shot_cooldown: float = 0.0
var _reload_remaining: float = 0.0
var _shot_sequence: int = 0
var _owner_body: CollisionObject3D

func _ready() -> void:
	assert(definition != null and definition.is_valid(), "GameWeapon3D requires a valid WeaponDefinition")
	_owner_body = get_node_or_null(owner_body_path) as CollisionObject3D
	_align_to_owner_muzzle()
	ammo_in_magazine = definition.magazine_capacity if initial_magazine < 0 else clampi(initial_magazine, 0, definition.magazine_capacity)
	if definition.infinite_reserve:
		reserve_ammo = -1
	elif initial_reserve_ammo >= 0:
		reserve_ammo = mini(initial_reserve_ammo, definition.max_reserve_ammo)
	else:
		reserve_ammo = definition.starting_reserve_ammo
	current_spread_degrees = definition.minimum_spread_degrees
	_emit_ammo_state()

func _physics_process(delta: float) -> void:
	_shot_cooldown = maxf(0.0, _shot_cooldown - delta)
	current_spread_degrees = maxf(
		definition.minimum_spread_degrees,
		current_spread_degrees - definition.spread_recovery_degrees_per_second * delta
	)
	if _reload_remaining > 0.0:
		_reload_remaining = maxf(0.0, _reload_remaining - delta)
		if is_zero_approx(_reload_remaining):
			_finish_reload()

func try_fire(direction: Vector3) -> bool:
	if not can_fire() or direction.length_squared() <= 0.0001:
		return false
	var shot_direction := _apply_spread(direction.normalized())
	var result := _perform_shot(shot_direction)
	var endpoint: Vector3 = result.get("endpoint", global_position + shot_direction * definition.range_meters)
	ammo_in_magazine -= 1
	_shot_cooldown = definition.shot_interval_seconds
	current_spread_degrees = minf(
		definition.maximum_spread_degrees,
		current_spread_degrees + definition.spread_per_shot_degrees
	)
	_shot_sequence += 1
	ammo_changed.emit(ammo_in_magazine, definition.magazine_capacity)
	fired.emit(global_position, endpoint, result.get("hit", false))
	if result.get("damaged", false):
		damage_confirmed.emit(result.get("target"), endpoint, result.get("damage", definition.damage))
	_emit_sound_event()
	if ammo_in_magazine <= 0:
		if definition.infinite_reserve or reserve_ammo > 0:
			_start_reload()
		else:
			out_of_ammo.emit()
	return true

func can_fire() -> bool:
	return _shot_cooldown <= 0.0 and _reload_remaining <= 0.0 and ammo_in_magazine > 0

func is_reloading() -> bool:
	return _reload_remaining > 0.0

func has_any_ammo() -> bool:
	return ammo_in_magazine > 0 or definition.infinite_reserve or reserve_ammo > 0

func add_reserve_ammo(amount: int) -> int:
	if amount <= 0 or definition.infinite_reserve:
		return 0
	var previous := reserve_ammo
	reserve_ammo = mini(definition.max_reserve_ammo, reserve_ammo + amount)
	reserve_changed.emit(reserve_ammo, definition.max_reserve_ammo)
	if ammo_in_magazine <= 0 and reserve_ammo > 0 and not is_reloading():
		_start_reload()
	return reserve_ammo - previous

func set_ammo_state(magazine: int, reserve: int) -> void:
	ammo_in_magazine = clampi(magazine, 0, definition.magazine_capacity)
	reserve_ammo = -1 if definition.infinite_reserve else clampi(reserve, 0, definition.max_reserve_ammo)
	_emit_ammo_state()

func set_owner_body(owner_body: CollisionObject3D) -> void:
	_owner_body = owner_body
	_align_to_owner_muzzle()

func _align_to_owner_muzzle() -> void:
	if _owner_body == null or definition == null:
		return
	global_position = _owner_body.to_global(definition.muzzle_position)

func get_aim_endpoint(direction: Vector3) -> Vector3:
	return global_position + direction.normalized() * definition.range_meters

func _perform_shot(direction: Vector3) -> Dictionary:
	return {"endpoint": get_aim_endpoint(direction), "hit": false}

func _start_reload() -> void:
	if _reload_remaining > 0.0 or (not definition.infinite_reserve and reserve_ammo <= 0):
		return
	_reload_remaining = definition.reload_seconds
	reload_started.emit(_reload_remaining)

func _finish_reload() -> void:
	var needed := definition.magazine_capacity - ammo_in_magazine
	if definition.infinite_reserve:
		ammo_in_magazine += needed
	else:
		var loaded := mini(needed, reserve_ammo)
		ammo_in_magazine += loaded
		reserve_ammo -= loaded
	_emit_ammo_state()
	reload_finished.emit()
	if ammo_in_magazine <= 0:
		out_of_ammo.emit()

func _apply_spread(direction: Vector3) -> Vector3:
	if current_spread_degrees <= 0.001:
		return direction
	var sign_value := -1.0 if _shot_sequence % 2 == 0 else 1.0
	var ring_index := (_shot_sequence >> 1) % 3
	var ring_step := float(ring_index + 1) / 3.0
	var yaw := deg_to_rad(current_spread_degrees * sign_value * ring_step)
	return direction.rotated(Vector3.UP, yaw).normalized()

func _emit_sound_event() -> void:
	var hub := GameSoundEventHub.find_in_tree(self)
	if hub != null:
		hub.emit_sound_event(
			global_position,
			definition.sound_radius_meters,
			definition.sound_priority,
			_owner_body
		)

func _emit_ammo_state() -> void:
	ammo_changed.emit(ammo_in_magazine, definition.magazine_capacity)
	reserve_changed.emit(reserve_ammo, definition.max_reserve_ammo)
