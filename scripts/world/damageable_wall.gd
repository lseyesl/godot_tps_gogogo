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
	var hub := GameSoundEventHub.find_in_tree(self)
	if hub != null:
		hub.emit_sound_event(
			global_position,
			20.0,
			GameSoundEventHub.Priority.ENVIRONMENT,
			self
		)
	destroyed.emit(self)
	queue_free()
