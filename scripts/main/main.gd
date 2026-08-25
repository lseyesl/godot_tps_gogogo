extends Node3D

@onready var _player: PlayerCharacter = $Player
@onready var _health_label: Label = %HealthLabel
@onready var _ammo_label: Label = %AmmoLabel
@onready var _guard_state_label: Label = %GuardStateLabel
@onready var _guard: PistolGuard = $PistolGuard
@onready var _mission: GameMissionController = $MissionController
@onready var _objective_status_label: Label = %ObjectiveStatusLabel
@onready var _enemy_count_label: Label = %EnemyCountLabel
@onready var _activation_progress: ProgressBar = %ActivationProgress
@onready var _result_panel: PanelContainer = %ResultPanel
@onready var _result_title: Label = %ResultTitle
@onready var _result_details: Label = %ResultDetails
@onready var _default_weapon_button: Button = %DefaultWeaponButton
@onready var _special_weapon_button: Button = %SpecialWeaponButton
@onready var _swap_weapon_button: Button = %SwapWeaponButton

func _ready() -> void:
	_player.health.health_changed.connect(_on_health_changed)
	_player.weapon_changed.connect(_on_weapon_changed)
	_player.weapon_swap_available.connect(_on_weapon_swap_available)
	_mission.phase_changed.connect(_on_mission_phase_changed)
	_mission.objective_progress.connect(_on_objective_progress)
	_mission.remaining_guards_changed.connect(_on_remaining_guards_changed)
	_mission.mission_completed.connect(_on_mission_completed)
	_mission.mission_failed.connect(_on_mission_failed)
	_default_weapon_button.pressed.connect(_player.switch_to_default_weapon)
	_special_weapon_button.pressed.connect(_player.switch_to_special_weapon)
	_swap_weapon_button.pressed.connect(_player.confirm_weapon_swap)
	_on_health_changed(_player.health.current_health, _player.health.max_health)
	_bind_weapon(_player.weapon)
	_on_mission_phase_changed(_mission.current_phase, _mission.current_phase)
	_on_remaining_guards_changed(_mission.remaining_guards)
	_guard.state_changed.connect(_on_guard_state_changed)
	_on_guard_state_changed(_guard.current_state, _guard.current_state)

func _on_health_changed(current: float, maximum: float) -> void:
	_health_label.text = "HP  %d / %d" % [int(current), int(maximum)]

func _on_ammo_changed(_current: int, _capacity: int, source: GameWeapon3D) -> void:
	if source == _player.weapon:
		_refresh_weapon_hud()

func _on_reserve_changed(_reserve: int, _maximum: int, source: GameWeapon3D) -> void:
	if source == _player.weapon:
		_refresh_weapon_hud()

func _on_weapon_changed(next_weapon: GameWeapon3D, _slot: int) -> void:
	_bind_weapon(next_weapon)

func _bind_weapon(next_weapon: GameWeapon3D) -> void:
	var ammo_callable := _on_ammo_changed.bind(next_weapon)
	if not next_weapon.ammo_changed.is_connected(ammo_callable):
		next_weapon.ammo_changed.connect(ammo_callable)
	var reserve_callable := _on_reserve_changed.bind(next_weapon)
	if not next_weapon.reserve_changed.is_connected(reserve_callable):
		next_weapon.reserve_changed.connect(reserve_callable)
	_refresh_weapon_hud()

func _refresh_weapon_hud() -> void:
	var current := _player.weapon
	var reserve_text := "∞" if current.definition.infinite_reserve else str(current.reserve_ammo)
	_ammo_label.text = "%s  %d / %d  ·  %s" % [
		current.definition.display_name.to_upper(),
		current.ammo_in_magazine,
		current.definition.magazine_capacity,
		reserve_text,
	]
	_default_weapon_button.disabled = _player.current_weapon_slot == PlayerCharacter.WeaponSlot.DEFAULT
	_special_weapon_button.disabled = _player.current_weapon_slot == PlayerCharacter.WeaponSlot.SPECIAL
	_special_weapon_button.text = (
		"SPECIAL\nEMPTY"
		if _player.special_weapon == null
		else "%s\n%d + %d" % [
			_player.special_weapon.definition.display_name.to_upper(),
			_player.special_weapon.ammo_in_magazine,
			maxi(0, _player.special_weapon.reserve_ammo),
		]
	)

func _on_weapon_swap_available(_pickup: Node, visible: bool) -> void:
	_swap_weapon_button.visible = visible

func _on_mission_phase_changed(_previous: int, current: int) -> void:
	match current:
		GameMissionController.MissionPhase.INFILTRATION:
			_objective_status_label.text = "目标：前往任务点"
		GameMissionController.MissionPhase.EXTRACTION:
			_objective_status_label.text = "目标：返回出生点撤离"
		GameMissionController.MissionPhase.WON:
			_objective_status_label.text = "任务完成"
		GameMissionController.MissionPhase.FAILED:
			_objective_status_label.text = "任务失败"

func _on_objective_progress(_elapsed: float, _duration: float, normalized: float) -> void:
	_activation_progress.visible = normalized > 0.0 and normalized < 1.0
	_activation_progress.value = normalized * 100.0

func _on_remaining_guards_changed(remaining: int) -> void:
	_enemy_count_label.text = "剩余警卫：%d" % remaining

func _on_mission_completed(summary: Dictionary) -> void:
	_show_result("撤离成功", summary)

func _on_mission_failed(summary: Dictionary) -> void:
	_show_result("任务失败", summary)

func _show_result(title: String, summary: Dictionary) -> void:
	_activation_progress.visible = false
	_result_panel.visible = true
	_result_title.text = title
	var elapsed: float = summary.get("elapsed_seconds", 0.0)
	var total_seconds := int(elapsed)
	var minutes := floori(elapsed / 60.0)
	var seconds := total_seconds % 60
	_result_details.text = "用时  %02d:%02d\n击杀  %d\n剩余生命  %d\n撤离  %s" % [
		minutes,
		seconds,
		int(summary.get("kills", 0)),
		int(summary.get("remaining_health", 0.0)),
		"完成" if summary.get("extracted", false) else "未完成",
	]

func _on_guard_state_changed(_previous: int, current: int) -> void:
	_guard_state_label.text = "GUARD  %s" % PistolGuard.GuardState.keys()[current]
