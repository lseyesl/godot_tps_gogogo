class_name GameMissionController
extends Node

signal phase_changed(previous: int, current: int)
signal objective_progress(elapsed: float, duration: float, normalized: float)
signal remaining_guards_changed(remaining: int)
signal mission_completed(summary: Dictionary)
signal mission_failed(summary: Dictionary)

enum MissionPhase {
	INFILTRATION,
	EXTRACTION,
	WON,
	FAILED,
}

@export var player_path: NodePath
@export var objective_path: NodePath
@export var extraction_path: NodePath

var current_phase := MissionPhase.INFILTRATION
var elapsed_seconds: float = 0.0
var kills: int = 0
var remaining_guards: int = 0

@onready var player: PlayerCharacter = get_node(player_path) as PlayerCharacter
@onready var objective: GameObjectivePoint3D = get_node(objective_path) as GameObjectivePoint3D
@onready var extraction: GameExtractionPoint3D = get_node(extraction_path) as GameExtractionPoint3D

func _ready() -> void:
	objective.activation_progress.connect(_on_objective_progress)
	objective.activated.connect(_on_objective_activated)
	extraction.extracted.connect(_on_extracted)
	player.died.connect(_on_player_died)
	extraction.set_extraction_enabled(false)
	_bind_guards()

func _process(delta: float) -> void:
	if current_phase == MissionPhase.INFILTRATION or current_phase == MissionPhase.EXTRACTION:
		elapsed_seconds += delta

func get_current_target() -> Node3D:
	if current_phase == MissionPhase.INFILTRATION:
		return objective
	if current_phase == MissionPhase.EXTRACTION:
		return extraction
	return null

func get_distance_band(distance_meters: float) -> String:
	if distance_meters < 10.0:
		return "近"
	if distance_meters < 24.0:
		return "中"
	return "远"

func _bind_guards() -> void:
	remaining_guards = 0
	for node in get_tree().get_nodes_in_group("guards"):
		var guard := node as PistolGuard
		if guard == null or guard.current_state == PistolGuard.GuardState.DEAD:
			continue
		remaining_guards += 1
		if not guard.died.is_connected(_on_guard_died):
			guard.died.connect(_on_guard_died)
	remaining_guards_changed.emit(remaining_guards)

func _on_objective_progress(elapsed: float, duration: float, normalized: float) -> void:
	if current_phase == MissionPhase.INFILTRATION:
		objective_progress.emit(elapsed, duration, normalized)

func _on_objective_activated(point: GameObjectivePoint3D) -> void:
	if current_phase != MissionPhase.INFILTRATION:
		return
	_set_phase(MissionPhase.EXTRACTION)
	extraction.set_extraction_enabled(true)
	for node in get_tree().get_nodes_in_group("guards"):
		if node is PistolGuard:
			(node as PistolGuard).alert_to_objective(point.global_position)

func _on_guard_died(_guard: PistolGuard) -> void:
	kills += 1
	remaining_guards = maxi(0, remaining_guards - 1)
	remaining_guards_changed.emit(remaining_guards)

func _on_extracted(_player: PlayerCharacter) -> void:
	if current_phase != MissionPhase.EXTRACTION:
		return
	_set_phase(MissionPhase.WON)
	_stop_combat()
	mission_completed.emit(_build_summary(true))

func _on_player_died() -> void:
	if current_phase == MissionPhase.WON or current_phase == MissionPhase.FAILED:
		return
	_set_phase(MissionPhase.FAILED)
	_stop_combat()
	mission_failed.emit(_build_summary(false))

func _set_phase(next_phase: int) -> void:
	if current_phase == next_phase:
		return
	var previous := current_phase
	current_phase = next_phase
	phase_changed.emit(previous, current_phase)

func _stop_combat() -> void:
	player.set_controls_enabled(false)
	player.set_physics_process(false)
	objective.set_physics_process(false)
	for node in get_tree().get_nodes_in_group("guards"):
		if node is PistolGuard:
			(node as PistolGuard).set_physics_process(false)

func _build_summary(extracted_successfully: bool) -> Dictionary:
	return {
		"elapsed_seconds": elapsed_seconds,
		"kills": kills,
		"remaining_health": player.health.current_health,
		"extracted": extracted_successfully,
	}
