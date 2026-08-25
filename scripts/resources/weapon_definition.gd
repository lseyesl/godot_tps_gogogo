class_name WeaponDefinition
extends Resource

@export_category("Identity")
@export var display_name: String = "Standard Pistol"

@export_category("Combat")
@export_range(0.0, 100.0, 0.1) var damage: float = 1.0
@export_range(0.1, 100.0, 0.1) var range_meters: float = 16.0
@export_range(0.01, 10.0, 0.01) var shot_interval_seconds: float = 0.45
@export_range(1, 999, 1) var magazine_capacity: int = 6
@export_range(0.01, 10.0, 0.01) var reload_seconds: float = 1.2
@export var automatic: bool = false

func is_valid() -> bool:
	return (
		damage > 0.0
		and range_meters > 0.0
		and shot_interval_seconds > 0.0
		and magazine_capacity > 0
		and reload_seconds > 0.0
	)
