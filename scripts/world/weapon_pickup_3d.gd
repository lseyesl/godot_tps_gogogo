class_name GameWeaponPickup3D
extends Area3D

signal collected(pickup: GameWeaponPickup3D, player: PlayerCharacter)

@export var definition: WeaponDefinition
@export var stored_magazine: int = -1
@export var stored_reserve: int = -1
@export var rotate_speed: float = 1.1

@onready var visual: MeshInstance3D = $Visual
@onready var label: Label3D = $Label3D

func _ready() -> void:
	assert(definition != null and definition.is_valid(), "Weapon pickup requires a valid definition")
	add_to_group("weapon_pickups")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	label.text = definition.display_name
	_apply_visual_style()

func _process(delta: float) -> void:
	visual.rotate_y(rotate_speed * delta)

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
	var material := StandardMaterial3D.new()
	material.metallic = 0.62
	material.roughness = 0.3
	match definition.weapon_id:
		&"heavy_pistol":
			material.albedo_color = Color(0.92, 0.72, 0.2, 1)
		&"machine_gun":
			material.albedo_color = Color(0.2, 0.55, 0.92, 1)
		&"rocket_launcher":
			material.albedo_color = Color(0.88, 0.2, 0.12, 1)
		_:
			material.albedo_color = Color(0.65, 0.68, 0.72, 1)
	visual.material_override = material
