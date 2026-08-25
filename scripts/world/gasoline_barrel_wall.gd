class_name GasolineBarrelWall
extends GameEnvironmentModule3D

signal exploded(barrel: GasolineBarrelWall)

@export var explosion_radius_meters: float = 3.0
@export var explosion_center_damage: float = 3.0
@export var explosion_edge_damage: float = 1.0

var has_exploded := false

@onready var health: HealthComponent = $HealthComponent

func _ready() -> void:
	super._ready()
	add_to_group("gasoline_barrels")
	add_to_group("flammable_modules")
	health.depleted.connect(_on_depleted)

func apply_damage(amount: float, source: Node = null) -> float:
	if has_exploded or not environment_active:
		return 0.0
	return health.apply_damage(amount, source)

func ignite_from_fire(_source: Node = null) -> void:
	_explode()

func _on_depleted(_source: Node) -> void:
	_explode()

func _explode() -> void:
	if has_exploded or not environment_active:
		return
	has_exploded = true
	deactivate_environment_module()
	var hub := get_reaction_hub()
	if hub != null:
		hub.request_explosion(
			global_position + Vector3.UP,
			explosion_radius_meters,
			explosion_center_damage,
			explosion_edge_damage,
			self
		)
	exploded.emit(self)
	queue_free()
