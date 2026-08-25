class_name PlayerCharacter
extends CharacterBody3D

signal died
signal weapon_changed(weapon: GameWeapon3D, slot: int)
signal weapon_swap_available(pickup: Node, visible: bool)

enum WeaponSlot {
	DEFAULT,
	SPECIAL,
}

@export var move_speed: float = 4.5
@export var turn_speed_radians: float = 16.0
@export var footstep_interval_seconds: float = 0.45
@export var footstep_radius_meters: float = 4.0

var aim_direction := Vector3(0.0, 0.0, -1.0)
var _move_input := Vector2.ZERO
var _requested_aim := Vector2(0.0, -1.0)
var _footstep_timer := 0.0
var special_weapon: GameWeapon3D
var current_weapon_slot := WeaponSlot.DEFAULT
var _offered_swap_pickup: Node

@onready var health: HealthComponent = $HealthComponent
@onready var default_weapon: GameWeapon3D = $WeaponPivot/Muzzle/StandardPistol
@onready var weapon: GameWeapon3D = default_weapon
@onready var aim_line: AimLine3D = $AimLine3D
@onready var vision: GameVisionSensor3D = $VisionSensor3D

func _ready() -> void:
	add_to_group("player")
	add_to_group("explosion_targets")
	add_to_group("fire_damage_targets")
	health.depleted.connect(_on_health_depleted)
	default_weapon.set_owner_body(self)

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

func equip_special_weapon(
	definition: WeaponDefinition,
	magazine: int = -1,
	reserve: int = -1
) -> Dictionary:
	if definition == null or definition.weapon_id == &"standard_pistol":
		return {}
	if special_weapon != null and special_weapon.definition.weapon_id == definition.weapon_id:
		special_weapon.add_reserve_ammo(definition.pickup_reserve_ammo if reserve < 0 else reserve)
		return {}
	var replaced: Dictionary = {}
	if special_weapon != null:
		replaced = {
			"definition": special_weapon.definition,
			"magazine": special_weapon.ammo_in_magazine,
			"reserve": special_weapon.reserve_ammo,
		}
		if weapon == special_weapon:
			_set_current_weapon(default_weapon, WeaponSlot.DEFAULT)
		special_weapon.queue_free()
	var new_weapon: GameWeapon3D
	if definition.weapon_type == WeaponDefinition.WeaponType.ROCKET:
		new_weapon = RocketWeapon.new()
	else:
		new_weapon = HitscanWeapon.new()
	new_weapon.name = String(definition.weapon_id)
	new_weapon.definition = definition
	new_weapon.initial_magazine = magazine
	new_weapon.initial_reserve_ammo = definition.starting_reserve_ammo if reserve < 0 else reserve
	$WeaponPivot/Muzzle.add_child(new_weapon)
	new_weapon.set_owner_body(self)
	new_weapon.out_of_ammo.connect(_on_special_weapon_out_of_ammo)
	special_weapon = new_weapon
	_set_current_weapon(special_weapon, WeaponSlot.SPECIAL)
	return replaced

func switch_to_default_weapon() -> void:
	_set_current_weapon(default_weapon, WeaponSlot.DEFAULT)

func switch_to_special_weapon() -> bool:
	if special_weapon == null or not special_weapon.has_any_ammo():
		return false
	_set_current_weapon(special_weapon, WeaponSlot.SPECIAL)
	return true

func offer_weapon_swap(pickup: Node) -> void:
	_offered_swap_pickup = pickup
	weapon_swap_available.emit(pickup, pickup != null)

func clear_weapon_swap_offer(pickup: Node) -> void:
	if _offered_swap_pickup != pickup:
		return
	_offered_swap_pickup = null
	weapon_swap_available.emit(null, false)

func confirm_weapon_swap() -> bool:
	if _offered_swap_pickup == null or not is_instance_valid(_offered_swap_pickup):
		return false
	if not _offered_swap_pickup.has_method("collect_for_player"):
		return false
	_offered_swap_pickup.call("collect_for_player", self, true)
	return true

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

func _on_special_weapon_out_of_ammo() -> void:
	if weapon == special_weapon:
		switch_to_default_weapon()

func _set_current_weapon(next_weapon: GameWeapon3D, slot: int) -> void:
	if next_weapon == null:
		return
	weapon = next_weapon
	current_weapon_slot = slot
	aim_line.set_weapon(weapon)
	weapon_changed.emit(weapon, current_weapon_slot)

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
