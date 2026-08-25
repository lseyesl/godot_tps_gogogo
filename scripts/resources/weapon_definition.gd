class_name WeaponDefinition
extends Resource

enum WeaponType {
	HITSCAN,
	ROCKET,
}

@export_category("Identity")
@export var weapon_id: StringName = &"standard_pistol"
@export var display_name: String = "Standard Pistol"
@export var weapon_type := WeaponType.HITSCAN

@export_category("Combat")
@export_range(0.0, 100.0, 0.1) var damage: float = 1.0
@export_range(0.1, 100.0, 0.1) var range_meters: float = 16.0
@export_range(0.01, 10.0, 0.01) var shot_interval_seconds: float = 0.45
@export_range(1, 999, 1) var magazine_capacity: int = 6
@export_range(0.01, 10.0, 0.01) var reload_seconds: float = 1.2
@export var automatic: bool = false

@export_category("Ammunition")
@export var infinite_reserve: bool = true
@export_range(0, 999, 1) var starting_reserve_ammo: int = 0
@export_range(0, 999, 1) var max_reserve_ammo: int = 0
@export_range(0, 999, 1) var pickup_reserve_ammo: int = 0

@export_category("Accuracy")
@export_range(0.0, 30.0, 0.1) var minimum_spread_degrees: float = 0.0
@export_range(0.0, 30.0, 0.1) var maximum_spread_degrees: float = 0.0
@export_range(0.0, 10.0, 0.05) var spread_per_shot_degrees: float = 0.0
@export_range(0.0, 30.0, 0.1) var spread_recovery_degrees_per_second: float = 0.0

@export_category("Rocket")
@export_range(0.1, 100.0, 0.1) var projectile_speed_meters_per_second: float = 10.0
@export_range(0.0, 20.0, 0.1) var explosion_radius_meters: float = 0.0
@export_range(0.0, 100.0, 0.1) var explosion_center_damage: float = 0.0
@export_range(0.0, 100.0, 0.1) var explosion_edge_damage: float = 0.0

@export_category("Perception")
@export_range(0.0, 100.0, 0.1) var sound_radius_meters: float = 24.0
@export_range(1, 10, 1) var sound_priority: int = 3

func is_valid() -> bool:
	return (
		not weapon_id.is_empty()
		and
		damage > 0.0
		and range_meters > 0.0
		and shot_interval_seconds > 0.0
		and magazine_capacity > 0
		and reload_seconds > 0.0
		and sound_radius_meters >= 0.0
		and sound_priority > 0
		and maximum_spread_degrees >= minimum_spread_degrees
		and (infinite_reserve or max_reserve_ammo >= starting_reserve_ammo)
		and (
			weapon_type == WeaponType.HITSCAN
			or (
				projectile_speed_meters_per_second > 0.0
				and explosion_radius_meters > 0.0
				and explosion_center_damage > 0.0
			)
		)
	)
