class_name GameTouchInputRouter
extends Control

@export var player_path: NodePath
@export var move_joystick_path: NodePath
@export var aim_joystick_path: NodePath
@export var fire_button_path: NodePath

@onready var _player: PlayerCharacter = get_node(player_path) as PlayerCharacter
@onready var _move_joystick: GameVirtualJoystick = get_node(move_joystick_path) as GameVirtualJoystick
@onready var _aim_joystick: GameVirtualJoystick = get_node(aim_joystick_path) as GameVirtualJoystick
@onready var _fire_button: GameFireAimButton = get_node(fire_button_path) as GameFireAimButton

var _fire_held := false

func _ready() -> void:
	_move_joystick.vector_changed.connect(_on_move_changed)
	_aim_joystick.vector_changed.connect(_on_aim_changed)
	_fire_button.fire_pressed.connect(_on_fire_pressed)
	_fire_button.fire_released.connect(_on_fire_released)

func _process(_delta: float) -> void:
	if _fire_held and _player.weapon.definition.automatic:
		_player.request_fire()

func _on_move_changed(value: Vector2) -> void:
	_player.set_move_input(value)

func _on_aim_changed(value: Vector2) -> void:
	_player.set_aim_input(value, value.length_squared() > 0.01)

func _on_fire_pressed() -> void:
	_fire_held = true
	_player.request_fire()

func _on_fire_released() -> void:
	_fire_held = false
	_player.release_fire()
