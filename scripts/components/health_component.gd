class_name HealthComponent
extends Node

signal health_changed(current: float, maximum: float)
signal damaged(amount: float, source: Node)
signal depleted(source: Node)

@export_range(0.1, 1000.0, 0.1) var max_health: float = 5.0
@export var reset_on_ready: bool = true

var current_health: float

func _ready() -> void:
	if reset_on_ready or current_health <= 0.0:
		current_health = max_health
	health_changed.emit(current_health, max_health)

func apply_damage(amount: float, source: Node = null) -> float:
	if amount <= 0.0 or current_health <= 0.0:
		return 0.0
	var applied := minf(amount, current_health)
	current_health -= applied
	damaged.emit(applied, source)
	health_changed.emit(current_health, max_health)
	if is_zero_approx(current_health):
		depleted.emit(source)
	return applied

func heal(amount: float) -> float:
	if amount <= 0.0 or current_health <= 0.0:
		return 0.0
	var previous := current_health
	current_health = minf(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
	return current_health - previous

func reset_health() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
