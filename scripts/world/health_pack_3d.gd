class_name GameHealthPack3D
extends Area3D

signal collected(pack: GameHealthPack3D, player: PlayerCharacter, healed: float)

@export_range(0.1, 10.0, 0.1) var heal_amount: float = 2.0
@export var rotate_speed: float = 0.8

var _player: PlayerCharacter

@onready var _visual_root: Node3D = $VisualRoot

func _ready() -> void:
	add_to_group("health_pickups")
	body_entered.connect(_on_body_entered)
	_resolve_player()

func _process(delta: float) -> void:
	_visual_root.rotate_y(rotate_speed * delta)
	if _player == null or not is_instance_valid(_player):
		_resolve_player()
	if _player != null and _player.vision != null:
		_visual_root.visible = _player.vision.can_see(self)

func collect_for_player(player: PlayerCharacter) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	var healed := player.health.heal(heal_amount)
	if healed <= 0.0:
		return false
	collected.emit(self, player, healed)
	monitoring = false
	visible = false
	queue_free()
	return true

func _on_body_entered(body: Node3D) -> void:
	if body is PlayerCharacter:
		collect_for_player(body as PlayerCharacter)

func _resolve_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as PlayerCharacter
