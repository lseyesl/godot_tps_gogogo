extends SceneTree

const MAXIMUM_FORWARD_ERROR := 0.22
const MAXIMUM_LATERAL_ERROR := 0.28
const WEAPON_REGION_MINIMUM := Vector3(0.1, 0.65, -INF)
const WEAPON_REGION_MAXIMUM := Vector3(1.2, 1.55, INF)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/actors/player.tscn") as PackedScene
	var player := packed.instantiate() as PlayerCharacter
	root.add_child(player)
	await process_frame
	var variants := {
		"pistol": {
			"miniature": player.pistol_miniature,
			"definition": load("res://resources/weapons/standard_pistol.tres") as WeaponDefinition,
		},
		"rifle": {
			"miniature": player.rifle_miniature,
			"definition": load("res://resources/weapons/machine_gun.tres") as WeaponDefinition,
		},
		"rocket": {
			"miniature": player.rocket_miniature,
			"definition": load("res://resources/weapons/rocket_launcher.tres") as WeaponDefinition,
		},
	}
	var failures := PackedStringArray()
	for variant_name in variants:
		var variant: Dictionary = variants[variant_name]
		var logical_muzzle: Vector3 = (variant.definition as WeaponDefinition).muzzle_position
		var extents := _find_visual_weapon_extents(player, variant.miniature as Node3D)
		var tip: Vector3 = extents.negative_z
		var forward_error := absf(logical_muzzle.z - tip.z)
		var lateral_error := Vector2(logical_muzzle.x - tip.x, logical_muzzle.y - tip.y).length()
		print("MUZZLE_ALIGNMENT variant=%s logical=%s visual_tip=%s forward_error=%.4f lateral_error=%.4f" % [
			variant_name,
			logical_muzzle,
			tip,
			forward_error,
			lateral_error,
		])
		if forward_error > MAXIMUM_FORWARD_ERROR or lateral_error > MAXIMUM_LATERAL_ERROR:
			failures.append("%s muzzle differs from its visible barrel" % variant_name)
	if not failures.is_empty():
		push_error("; ".join(failures))
		quit(1)
		return
	print("PASS: weapon rays start at their visible barrel tips")
	quit(0)

func _find_visual_weapon_extents(player: PlayerCharacter, miniature: Node3D) -> Dictionary:
	var candidates := PackedVector3Array()
	for child in miniature.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		for surface_index in mesh_instance.mesh.get_surface_count():
			var arrays := mesh_instance.mesh.surface_get_arrays(surface_index)
			if arrays.is_empty():
				continue
			for vertex in arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array:
				var point := player.to_local(mesh_instance.to_global(vertex))
				if (
					point.x >= WEAPON_REGION_MINIMUM.x
					and point.x <= WEAPON_REGION_MAXIMUM.x
					and point.y >= WEAPON_REGION_MINIMUM.y
					and point.y <= WEAPON_REGION_MAXIMUM.y
				):
					candidates.append(point)
	if candidates.is_empty():
		return {"negative_z": Vector3.INF, "positive_z": Vector3.INF}
	var minimum_z := INF
	for point in candidates:
		minimum_z = minf(minimum_z, point.z)
	var negative_sum := Vector3.ZERO
	var negative_count := 0
	for point in candidates:
		if point.z <= minimum_z + 0.04:
			negative_sum += point
			negative_count += 1
	return {
		"negative_z": negative_sum / float(maxi(1, negative_count)),
	}
