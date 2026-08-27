class_name GameWeaponPickup3D
extends Area3D

signal collected(pickup: GameWeaponPickup3D, player: PlayerCharacter)

const WEAPON_MODEL_PATHS := {
	&"heavy_pistol": "res://assets/models/prototypes/weapon-pistol.glb",
	&"machine_gun": "res://assets/models/prototypes/weapon-rifle.glb",
	&"rocket_launcher": "res://assets/models/prototypes/weapon-rocket-launcher.glb",
}

@export var definition: WeaponDefinition
@export var stored_magazine: int = -1
@export var stored_reserve: int = -1
@export var rotate_speed: float = 1.1

var _player: PlayerCharacter

@onready var visual: Node3D = $Visual
@onready var label: Label3D = $Label3D

func _ready() -> void:
	assert(definition != null and definition.is_valid(), "Weapon pickup requires a valid definition")
	add_to_group("weapon_pickups")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	label.text = definition.display_name
	_apply_visual_style()
	_resolve_player()

func _process(delta: float) -> void:
	visual.rotate_y(rotate_speed * delta)
	if _player == null or not is_instance_valid(_player):
		_resolve_player()
	if _player != null and _player.vision != null:
		visible = _player.vision.can_see(self)

func collect_for_player(player: PlayerCharacter, confirmed: bool = false) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if player.special_weapon == null:
		player.equip_special_weapon(definition, stored_magazine, _initial_reserve())
		_consume(player)
		return true
	if player.special_weapon.definition.weapon_id == definition.weapon_id:
		var amount := definition.pickup_reserve_ammo if stored_reserve < 0 else stored_reserve
		if player.special_weapon.add_reserve_ammo(amount) <= 0:
			return false
		_consume(player)
		return true
	if not confirmed:
		player.offer_weapon_swap(self)
		return false
	var replaced := player.equip_special_weapon(definition, stored_magazine, _initial_reserve())
	player.clear_weapon_swap_offer(self)
	if not replaced.is_empty():
		_spawn_replaced_pickup(replaced)
	_consume(player)
	return true

func _on_body_entered(body: Node3D) -> void:
	if body is PlayerCharacter:
		collect_for_player(body as PlayerCharacter)

func _on_body_exited(body: Node3D) -> void:
	if body is PlayerCharacter:
		(body as PlayerCharacter).clear_weapon_swap_offer(self)

func _initial_reserve() -> int:
	return definition.starting_reserve_ammo if stored_reserve < 0 else stored_reserve

func _consume(player: PlayerCharacter) -> void:
	collected.emit(self, player)
	monitoring = false
	visible = false
	queue_free()

func _spawn_replaced_pickup(state: Dictionary) -> void:
	var pickup_scene := load("res://scenes/world/weapon_pickup_3d.tscn") as PackedScene
	var dropped := pickup_scene.instantiate() as GameWeaponPickup3D
	dropped.definition = state.definition
	dropped.stored_magazine = state.magazine
	dropped.stored_reserve = state.reserve
	get_parent().add_child(dropped)
	dropped.global_position = global_position

func _apply_visual_style() -> void:
	var model_path: String = WEAPON_MODEL_PATHS.get(definition.weapon_id, "")
	if model_path.is_empty():
		return
	var model_scene := load(model_path) as PackedScene
	if model_scene == null:
		return
	var model := model_scene.instantiate() as Node3D
	model.name = "ImportedWeaponModel"
	model.scale = Vector3.ONE * 1.15
	visual.add_child(model)

func _resolve_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as PlayerCharacter
