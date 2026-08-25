class_name OilBarrelWall
extends GameEnvironmentModule3D

signal ignited(barrel: OilBarrelWall)
signal destroyed(barrel: OilBarrelWall)

@export var burn_duration_seconds: float = 4.0
@export var fire_damage_radius_meters: float = 1.25

var is_burning := false
var burn_remaining: float = 0.0
var _fire_tick_remaining: float = 1.0

@onready var health: HealthComponent = $HealthComponent
@onready var fire_indicator: Node3D = $FireIndicator

func _ready() -> void:
	super._ready()
	add_to_group("oil_barrels")
	add_to_group("flammable_modules")
	health.depleted.connect(_on_depleted)
	fire_indicator.visible = false

func _physics_process(delta: float) -> void:
	if not is_burning or not environment_active:
		return
	burn_remaining = maxf(0.0, burn_remaining - delta)
	_fire_tick_remaining = maxf(0.0, _fire_tick_remaining - delta)
	if is_zero_approx(_fire_tick_remaining):
		var hub := get_reaction_hub()
		if hub != null:
			hub.apply_fire_damage(global_position, fire_damage_radius_meters, self)
		_fire_tick_remaining = 1.0
	if is_zero_approx(burn_remaining):
		_finish_burning()

func apply_damage(amount: float, source: Node = null) -> float:
	if is_burning or not environment_active:
		return 0.0
	return health.apply_damage(amount, source)

func ignite_from_fire(_source: Node = null) -> void:
	_start_burning()

func _on_depleted(_source: Node) -> void:
	_start_burning()

func _start_burning() -> void:
	if is_burning or not environment_active:
		return
	is_burning = true
	burn_remaining = burn_duration_seconds
	_fire_tick_remaining = 1.0
	fire_indicator.visible = true
	add_to_group("active_fire")
	var reaction_hub := get_reaction_hub()
	if reaction_hub != null:
		reaction_hub.request_fire_propagation(self)
	var sound_hub := GameSoundEventHub.find_in_tree(self)
	if sound_hub != null:
		sound_hub.emit_sound_event(
			global_position,
			8.0,
			GameSoundEventHub.Priority.ENVIRONMENT,
			self
		)
	ignited.emit(self)

func _finish_burning() -> void:
	if not environment_active:
		return
	remove_from_group("active_fire")
	deactivate_environment_module()
	destroyed.emit(self)
	queue_free()
