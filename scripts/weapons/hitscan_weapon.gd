class_name HitscanWeapon
extends Marker3D

signal fired(origin: Vector3, endpoint: Vector3, hit: bool)
signal ammo_changed(in_magazine: int, magazine_capacity: int)
signal reload_started(duration: float)
signal reload_finished

@export var definition: WeaponDefinition
@export_flags_3d_physics var hit_mask: int = 10
@export var owner_body_path: NodePath

var ammo_in_magazine: int
var _shot_cooldown: float = 0.0
var _reload_remaining: float = 0.0

@onready var _owner_body: CollisionObject3D = get_node_or_null(owner_body_path) as CollisionObject3D

func _ready() -> void:
	assert(definition != null and definition.is_valid(), "HitscanWeapon requires a valid WeaponDefinition")
	ammo_in_magazine = definition.magazine_capacity
	ammo_changed.emit(ammo_in_magazine, definition.magazine_capacity)

func _physics_process(delta: float) -> void:
	_shot_cooldown = maxf(0.0, _shot_cooldown - delta)
	if _reload_remaining > 0.0:
		_reload_remaining = maxf(0.0, _reload_remaining - delta)
		if is_zero_approx(_reload_remaining):
			ammo_in_magazine = definition.magazine_capacity
			ammo_changed.emit(ammo_in_magazine, definition.magazine_capacity)
			reload_finished.emit()

func try_fire(direction: Vector3) -> bool:
	if not can_fire() or direction.length_squared() <= 0.0001:
		return false
	var normalized_direction := direction.normalized()
	var hit := _query_trajectory(normalized_direction)
	var endpoint: Vector3 = hit.get("position", global_position + normalized_direction * definition.range_meters)
	if not hit.is_empty():
		var collider := hit.get("collider") as Object
		if collider != null and collider.has_method("apply_damage"):
			collider.call("apply_damage", definition.damage, _owner_body)
	ammo_in_magazine -= 1
	_shot_cooldown = definition.shot_interval_seconds
	ammo_changed.emit(ammo_in_magazine, definition.magazine_capacity)
	fired.emit(global_position, endpoint, not hit.is_empty())
	if ammo_in_magazine <= 0:
		_start_reload()
	return true

func can_fire() -> bool:
	return _shot_cooldown <= 0.0 and _reload_remaining <= 0.0 and ammo_in_magazine > 0

func is_reloading() -> bool:
	return _reload_remaining > 0.0

func get_aim_endpoint(direction: Vector3) -> Vector3:
	if definition == null or direction.length_squared() <= 0.0001:
		return global_position
	var normalized_direction := direction.normalized()
	var hit := _query_trajectory(normalized_direction)
	return hit.get("position", global_position + normalized_direction * definition.range_meters)

func _query_trajectory(direction: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + direction * definition.range_meters,
		hit_mask
	)
	query.collide_with_areas = true
	if _owner_body != null:
		query.exclude = [_owner_body.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)

func _start_reload() -> void:
	if _reload_remaining > 0.0:
		return
	_reload_remaining = definition.reload_seconds
	reload_started.emit(_reload_remaining)
