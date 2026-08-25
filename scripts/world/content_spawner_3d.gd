class_name GameContentSpawner3D
extends Node3D

@export var guard_scene: PackedScene
@export var objective_scene: PackedScene
@export var weapon_pickup_scene: PackedScene
@export var health_pack_scene: PackedScene
@export var heavy_pistol_definition: WeaponDefinition
@export var machine_gun_definition: WeaponDefinition
@export var rocket_launcher_definition: WeaponDefinition
@export var guard_candidates_path: NodePath
@export var objective_candidates_path: NodePath
@export var weapon_candidates_path: NodePath
@export var health_candidates_path: NodePath

var layout_seed: int = 0
var layout_signature: Dictionary = {}

func _ready() -> void:
	add_to_group("content_spawners")
	var run_state := get_node("/root/GameRunState")
	generate_layout(int(run_state.call("get_or_create_seed")))

func generate_layout(seed_value: int) -> void:
	layout_seed = seed_value
	var random := RandomNumberGenerator.new()
	random.seed = layout_seed
	var guard_transforms := _shuffled_candidate_transforms(get_node(guard_candidates_path), random)
	var objective_transforms := _shuffled_candidate_transforms(get_node(objective_candidates_path), random)
	var weapon_transforms := _shuffled_candidate_transforms(get_node(weapon_candidates_path), random)
	var health_transforms := _shuffled_candidate_transforms(get_node(health_candidates_path), random)
	var guard_count := random.randi_range(8, 12)
	assert(guard_transforms.size() >= guard_count, "Not enough validated guard candidates")
	assert(not objective_transforms.is_empty(), "Objective candidates are required")
	assert(weapon_transforms.size() >= 4, "At least four weapon candidates are required")
	assert(health_transforms.size() >= 2, "At least two health candidates are required")

	var guard_entries: Array[String] = []
	for index in guard_count:
		var guard := guard_scene.instantiate() as PistolGuard
		guard.name = "PistolGuard" if index == 0 else "PistolGuard%02d" % (index + 1)
		add_child(guard)
		guard.global_transform = guard_transforms[index]
		guard_entries.append(_transform_key(guard.global_transform))

	var objective := objective_scene.instantiate() as GameObjectivePoint3D
	objective.name = "ObjectivePoint"
	add_child(objective)
	objective.global_transform = objective_transforms[0]

	var definitions: Array[WeaponDefinition] = [
		heavy_pistol_definition,
		machine_gun_definition,
		rocket_launcher_definition,
	]
	definitions.append(definitions[random.randi_range(0, definitions.size() - 1)])
	var weapon_entries: Array[String] = []
	for index in definitions.size():
		var pickup := weapon_pickup_scene.instantiate() as GameWeaponPickup3D
		pickup.definition = definitions[index]
		pickup.name = _weapon_node_name(definitions[index], index)
		add_child(pickup)
		pickup.global_transform = weapon_transforms[index]
		weapon_entries.append("%s@%s" % [definitions[index].weapon_id, _transform_key(pickup.global_transform)])

	var health_entries: Array[String] = []
	for index in 2:
		var health_pack := health_pack_scene.instantiate() as GameHealthPack3D
		health_pack.name = "HealthPack%d" % (index + 1)
		add_child(health_pack)
		health_pack.global_transform = health_transforms[index]
		health_entries.append(_transform_key(health_pack.global_transform))

	layout_signature = {
		"seed": layout_seed,
		"guard_count": guard_count,
		"guards": guard_entries,
		"objective": _transform_key(objective.global_transform),
		"weapons": weapon_entries,
		"health_packs": health_entries,
	}

func _shuffled_candidate_transforms(container: Node, random: RandomNumberGenerator) -> Array[Transform3D]:
	var candidates: Array[Transform3D] = []
	for child in container.get_children():
		if child is Node3D:
			candidates.append((child as Node3D).global_transform)
	for index in range(candidates.size() - 1, 0, -1):
		var swap_index := random.randi_range(0, index)
		var temporary := candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = temporary
	return candidates

func _weapon_node_name(definition: WeaponDefinition, index: int) -> String:
	if index == 3:
		return "BonusWeaponPickup"
	match definition.weapon_id:
		&"heavy_pistol":
			return "HeavyPistolPickup"
		&"machine_gun":
			return "MachineGunPickup"
		&"rocket_launcher":
			return "RocketLauncherPickup"
	return "WeaponPickup%d" % (index + 1)

func _transform_key(value: Transform3D) -> String:
	return "%.2f,%.2f,%.2f,%.3f" % [
		value.origin.x,
		value.origin.y,
		value.origin.z,
		value.basis.get_euler().y,
	]
