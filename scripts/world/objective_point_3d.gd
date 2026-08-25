class_name GameObjectivePoint3D
extends Area3D

signal activation_progress(elapsed: float, duration: float, normalized: float)
signal activated(objective: GameObjectivePoint3D)

@export_range(0.1, 30.0, 0.1) var activation_seconds: float = 3.0

var activation_elapsed: float = 0.0
var is_activated := false
var _player_inside: PlayerCharacter

@onready var _beacon: MeshInstance3D = $VisualRoot/Beacon
@onready var _label: Label3D = $VisualRoot/Label3D

func _ready() -> void:
	add_to_group("objective_points")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_apply_visual_state()

func _physics_process(delta: float) -> void:
	if is_activated or _player_inside == null or not is_instance_valid(_player_inside):
		return
	activation_elapsed = minf(activation_seconds, activation_elapsed + delta)
	activation_progress.emit(
		activation_elapsed,
		activation_seconds,
		activation_elapsed / activation_seconds
	)
	if activation_elapsed >= activation_seconds:
		_activate()

func reset_activation() -> void:
	if is_activated or is_zero_approx(activation_elapsed):
		return
	activation_elapsed = 0.0
	activation_progress.emit(0.0, activation_seconds, 0.0)

func _on_body_entered(body: Node3D) -> void:
	if is_activated or not body is PlayerCharacter:
		return
	_player_inside = body as PlayerCharacter

func _on_body_exited(body: Node3D) -> void:
	if body != _player_inside:
		return
	_player_inside = null
	reset_activation()

func _activate() -> void:
	if is_activated:
		return
	is_activated = true
	_player_inside = null
	activation_elapsed = activation_seconds
	activation_progress.emit(activation_seconds, activation_seconds, 1.0)
	_apply_visual_state()
	activated.emit(self)

func _apply_visual_state() -> void:
	if _beacon == null or _label == null:
		return
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.25, 1.0, 0.58, 0.72) if is_activated else Color(1.0, 0.72, 0.12, 0.72)
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 1.8
	_beacon.material_override = material
	_label.text = "任务已激活" if is_activated else "任务点 · 停留 3 秒"
