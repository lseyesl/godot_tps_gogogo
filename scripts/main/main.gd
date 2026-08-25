extends Node3D

@onready var _player: PlayerCharacter = $Player
@onready var _health_label: Label = %HealthLabel
@onready var _ammo_label: Label = %AmmoLabel
@onready var _guard_state_label: Label = %GuardStateLabel
@onready var _guard: PistolGuard = $PistolGuard

func _ready() -> void:
	_player.health.health_changed.connect(_on_health_changed)
	_player.weapon.ammo_changed.connect(_on_ammo_changed)
	_on_health_changed(_player.health.current_health, _player.health.max_health)
	_on_ammo_changed(_player.weapon.ammo_in_magazine, _player.weapon.definition.magazine_capacity)
	_guard.state_changed.connect(_on_guard_state_changed)
	_on_guard_state_changed(_guard.current_state, _guard.current_state)

func _on_health_changed(current: float, maximum: float) -> void:
	_health_label.text = "HP  %d / %d" % [int(current), int(maximum)]

func _on_ammo_changed(current: int, capacity: int) -> void:
	_ammo_label.text = "STANDARD PISTOL  %d / %d  ·  ∞" % [current, capacity]

func _on_guard_state_changed(_previous: int, current: int) -> void:
	_guard_state_label.text = "GUARD  %s" % PistolGuard.GuardState.keys()[current]
