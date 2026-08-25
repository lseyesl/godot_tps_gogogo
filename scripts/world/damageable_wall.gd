class_name DamageableWall
extends StaticBody3D

signal destroyed(wall: DamageableWall)

@onready var health: HealthComponent = $HealthComponent

func _ready() -> void:
	add_to_group("damageable_walls")
	health.depleted.connect(_on_depleted)

func apply_damage(amount: float, source: Node = null) -> float:
	return health.apply_damage(amount, source)

func _on_depleted(_source: Node) -> void:
	destroyed.emit(self)
	queue_free()
