extends SceneTree

var _failures: Array[String] = []
var _weapon_integration_completed := false
var _mission_integration_completed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_weapon_definition()
	await _test_weapon_runtime()
	_test_health_component()
	await _test_navigation_grid()
	await _test_cover_behavior()
	await _test_environment_reactions()
	await _test_main_scene()
	await _test_mission_loop()
	_expect(_mission_integration_completed, "mission integration test completes without runtime errors")
	await _test_weapon_pickups_and_rocket()
	_expect(_weapon_integration_completed, "weapon pickup and rocket integration test completes without runtime errors")
	await _test_sound_investigation()
	if _failures.is_empty():
		print("PASS: core slice tests")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

func _test_weapon_definition() -> void:
	var definition := load("res://resources/weapons/standard_pistol.tres") as WeaponDefinition
	_expect(definition != null, "standard pistol resource loads")
	if definition == null:
		return
	_expect(definition.is_valid(), "standard pistol resource is valid")
	_expect(is_equal_approx(definition.damage, 1.0), "standard pistol damage is 1")
	_expect(is_equal_approx(definition.range_meters, 16.0), "standard pistol range is 16 meters")
	_expect(definition.magazine_capacity == 6, "standard pistol magazine is 6")
	_expect(is_equal_approx(definition.sound_radius_meters, 24.0), "standard pistol sound radius is 12 modules")
	var heavy := load("res://resources/weapons/heavy_pistol.tres") as WeaponDefinition
	var machine_gun := load("res://resources/weapons/machine_gun.tres") as WeaponDefinition
	var rocket := load("res://resources/weapons/rocket_launcher.tres") as WeaponDefinition
	_expect(heavy != null and heavy.is_valid(), "heavy pistol resource is valid")
	_expect(heavy.damage == 2.0 and heavy.magazine_capacity == 6, "heavy pistol uses frozen damage and magazine values")
	_expect(not heavy.infinite_reserve and heavy.starting_reserve_ammo == 18, "heavy pistol starts with finite 18-round reserve")
	_expect(machine_gun != null and machine_gun.is_valid(), "machine gun resource is valid")
	_expect(machine_gun.automatic and is_equal_approx(machine_gun.shot_interval_seconds, 0.1), "machine gun supports held fire at ten rounds per second")
	_expect(machine_gun.magazine_capacity == 24 and machine_gun.starting_reserve_ammo == 48, "machine gun uses frozen ammunition values")
	_expect(rocket != null and rocket.is_valid(), "rocket launcher resource is valid")
	_expect(rocket.weapon_type == WeaponDefinition.WeaponType.ROCKET, "rocket launcher selects projectile firing")
	_expect(rocket.magazine_capacity == 1 and rocket.starting_reserve_ammo == 3, "rocket launcher uses one plus three ammunition")
	_expect(is_equal_approx(rocket.projectile_speed_meters_per_second, 10.0), "rocket travels at ten meters per second")
	_expect(is_equal_approx(rocket.explosion_radius_meters, 4.0), "rocket explosion radius is four meters")

func _test_weapon_runtime() -> void:
	var heavy_definition := load("res://resources/weapons/heavy_pistol.tres") as WeaponDefinition
	var heavy := GameWeapon3D.new()
	heavy.definition = heavy_definition
	root.add_child(heavy)
	for shot in heavy_definition.magazine_capacity:
		_expect(heavy.try_fire(Vector3.FORWARD), "finite weapon fires magazine round %d" % (shot + 1))
		heavy.call("_physics_process", heavy_definition.shot_interval_seconds + 0.01)
	_expect(heavy.is_reloading(), "empty finite magazine starts automatic reload")
	heavy.call("_physics_process", heavy_definition.reload_seconds + 0.01)
	_expect(heavy.ammo_in_magazine == 6, "automatic reload fills heavy pistol magazine")
	_expect(heavy.reserve_ammo == 12, "automatic reload consumes finite reserve ammunition")
	heavy.queue_free()
	await process_frame

	var machine_definition := load("res://resources/weapons/machine_gun.tres") as WeaponDefinition
	var machine := GameWeapon3D.new()
	machine.definition = machine_definition
	root.add_child(machine)
	var initial_spread := machine.current_spread_degrees
	for _shot in 4:
		_expect(machine.try_fire(Vector3.FORWARD), "machine gun accepts repeated cooldown-paced fire requests")
		machine.call("_physics_process", machine_definition.shot_interval_seconds + 0.01)
	_expect(machine.current_spread_degrees > initial_spread, "machine gun spread grows during sustained fire")
	var spread_after_burst := machine.current_spread_degrees
	machine.call("_physics_process", 1.0)
	_expect(machine.current_spread_degrees < spread_after_burst, "machine gun spread recovers after firing stops")
	machine.queue_free()
	await process_frame

func _test_health_component() -> void:
	var health := HealthComponent.new()
	health.max_health = 3.0
	health.reset_on_ready = false
	health.current_health = 3.0
	root.add_child(health)
	_expect(is_equal_approx(health.apply_damage(1.0), 1.0), "health applies one damage")
	_expect(is_equal_approx(health.current_health, 2.0), "health retains two points")
	_expect(is_equal_approx(health.heal(5.0), 1.0), "healing clamps at maximum")
	_expect(is_equal_approx(health.current_health, 3.0), "health returns to maximum")
	health.queue_free()

func _test_navigation_grid() -> void:
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	var debug_input := instance.get_node("DebugPlayerInput")
	debug_input.set_process(false)
	debug_input.set_process_unhandled_input(false)
	var guard := instance.get_node("PistolGuard") as PistolGuard
	guard.set_physics_process(false)
	var navigation := instance.get_node("GridNavigation3D") as GameGridNavigation3D
	var wall := instance.get_node("WoodWallD") as DamageableWall
	_expect(navigation != null, "main scene contains 2D grid navigation")
	_expect(navigation.is_world_position_blocked(Vector3(1.0, 0.0, -7.0)), "indestructible brick wall blocks overlapping navigation cells")
	_expect(navigation.is_world_position_blocked(wall.global_position), "intact wood wall blocks its navigation cell")
	var start := Vector3(3.0, 0.0, 5.0)
	var target := Vector3(3.0, 0.0, -5.0)
	var path_before := navigation.get_world_path(start, target)
	_expect(not path_before.is_empty(), "grid finds a route around intact wood wall")
	var revision_before := navigation.revision
	guard.global_position = start
	guard.call("_move_toward_navigation_target", target)
	_expect(guard.get("_planned_navigation_revision") == revision_before, "guard stores the navigation revision used for its route")
	wall.apply_damage(5.0)
	_expect(not navigation.is_world_position_blocked(Vector3(3.0, 0.0, -3.0)), "destroyed wood wall opens its navigation cell immediately")
	_expect(navigation.revision > revision_before, "wall destruction advances navigation revision")
	guard.call("_move_toward_navigation_target", target)
	_expect(guard.get("_planned_navigation_revision") == navigation.revision, "guard replans after navigation revision changes")
	var path_after := navigation.get_world_path(start, target)
	_expect(not path_after.is_empty(), "grid still finds a route after wall destruction")
	_expect(path_after.size() < path_before.size(), "opening a wall shortens the route through its former cell")
	instance.queue_free()
	await process_frame

func _test_cover_behavior() -> void:
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	var debug_input := instance.get_node("DebugPlayerInput")
	debug_input.set_process(false)
	debug_input.set_process_unhandled_input(false)
	var player := instance.get_node("Player") as PlayerCharacter
	var guard := instance.get_node("PistolGuard") as PistolGuard
	var cover_service := instance.get_node("CoverService3D") as GameCoverService3D
	guard.set_physics_process(false)
	player.set_physics_process(false)
	player.global_position = Vector3(0.0, 0.0, 5.0)
	guard.global_position = Vector3.ZERO
	guard.rotation.y = PI
	var cover := cover_service.find_best_cover(guard.global_position, player.global_position, 6.0)
	_expect(not cover.is_empty(), "guard finds reachable cover within three modules")
	if not cover.is_empty():
		_expect(cover_service.is_position_covered(cover.cover_position, player.global_position), "selected cover blocks the player ray")
		_expect(not cover_service.is_position_covered(cover.peek_position, player.global_position), "selected peek position has a clear player ray")
		guard.set("_last_known_player_position", player.global_position)
		_expect(guard.call("_begin_move_to_best_cover"), "guard begins moving to selected cover")
		_expect(guard.current_state == PistolGuard.GuardState.MOVE_TO_COVER, "cover selection enters move-to-cover state")
		guard.global_position = cover.cover_position
		guard.call("_process_move_to_cover", 0.016)
		_expect(guard.current_state == PistolGuard.GuardState.IN_COVER, "guard enters in-cover state after reaching cover")
		guard.set("_cover_timer", 0.0)
		guard.call("_process_in_cover", 0.016)
		guard.global_position = cover.peek_position
		var ammo_before_peek := guard.weapon.ammo_in_magazine
		guard.call("_process_in_cover", 0.016)
		guard.call("_process_in_cover", guard.shot_direction_lock_seconds + 0.01)
		_expect(guard.weapon.ammo_in_magazine == ammo_before_peek - 1, "guard fires one locked shot from peek position")
		_expect(not guard.get("_cover_is_peeking"), "guard returns to hidden cover phase after peek shot")
	for wall_name in ["WoodWallA", "WoodWallB", "WoodWallC", "WoodWallD"]:
		var wall := instance.get_node(wall_name) as DamageableWall
		wall.apply_damage(5.0)
	if not cover.is_empty():
		_expect(not cover_service.is_cover_valid(cover.cover_position, cover.peek_position, player.global_position), "destroying cover invalidates its candidate immediately")
		guard.call("_refresh_cover_if_needed")
		_expect(guard.current_state == PistolGuard.GuardState.COMBAT, "guard abandons destroyed cover when no replacement exists")
	guard.global_position = Vector3.ZERO
	guard.set("_last_known_player_position", player.global_position)
	guard.call("_apply_fallback_combat_movement")
	var away_from_player := (guard.global_position - player.global_position).normalized()
	_expect(guard.velocity.dot(away_from_player) > 0.0, "guard retreats when fighting inside preferred distance")
	guard.global_position = Vector3.ZERO
	player.global_position = Vector3(0.0, 0.0, 15.0)
	guard.set("_last_known_player_position", player.global_position)
	guard.call("_apply_fallback_combat_movement")
	var toward_distant_player := (player.global_position - guard.global_position).normalized()
	_expect(guard.velocity.dot(toward_distant_player) > 0.0, "guard advances when fighting beyond preferred distance")
	guard.global_position = Vector3.ZERO
	player.global_position = Vector3(0.0, 0.0, 10.0)
	guard.set("_last_known_player_position", player.global_position)
	var toward_band_player := (player.global_position - guard.global_position).normalized()
	guard.call("_apply_fallback_combat_movement")
	_expect(absf(guard.velocity.dot(toward_band_player)) < 0.01, "guard strafes laterally inside preferred distance band")
	instance.queue_free()
	await process_frame

func _test_environment_reactions() -> void:
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	var debug_input := instance.get_node("DebugPlayerInput")
	debug_input.set_process(false)
	debug_input.set_process_unhandled_input(false)
	var player := instance.get_node("Player") as PlayerCharacter
	var guard := instance.get_node("PistolGuard") as PistolGuard
	var navigation := instance.get_node("GridNavigation3D") as GameGridNavigation3D
	var reaction_hub := instance.get_node("EnvironmentReactionHub") as GameEnvironmentReactionHub
	var oil := instance.get_node("OilBarrelWall") as OilBarrelWall
	var burnable_wood := instance.get_node("BurnableWoodWall") as DamageableWall
	var gasoline := instance.get_node("GasolineBarrelWall") as GasolineBarrelWall
	guard.set_physics_process(false)
	player.set_physics_process(false)
	_expect(is_equal_approx(oil.health.max_health, 4.0), "oil barrel durability is four")
	_expect(is_equal_approx(gasoline.health.max_health, 3.0), "gasoline barrel durability is three")
	_expect(navigation.is_world_position_blocked(oil.global_position), "intact oil barrel blocks navigation")
	oil.apply_damage(4.0, player)
	_expect(oil.is_burning, "oil barrel enters burning state at zero durability")
	_expect(burnable_wood.is_burning, "fire ignites directly adjacent wood wall")
	_expect(gasoline.has_exploded, "burning wood immediately triggers adjacent gasoline barrel")
	_expect(not navigation.is_world_position_blocked(gasoline.global_position), "exploded gasoline barrel opens navigation immediately")
	_expect((gasoline.get_node("CollisionShape3D") as CollisionShape3D).disabled, "exploded gasoline barrel disables collision immediately")
	burnable_wood.call("_physics_process", 3.1)
	_expect(not burnable_wood.environment_active, "burning wood wall disappears after three seconds")
	_expect(not navigation.is_world_position_blocked(Vector3(-9.0, 0.0, 7.0)), "finished wood fire opens its navigation cell")

	var oil_scene := load("res://scenes/world/oil_barrel_wall.tscn") as PackedScene
	var wall_scene := load("res://scenes/world/damageable_wall.tscn") as PackedScene
	var isolated_oil := oil_scene.instantiate() as OilBarrelWall
	var diagonal_wall := wall_scene.instantiate() as DamageableWall
	isolated_oil.position = Vector3(11.0, 0.0, 7.0)
	diagonal_wall.position = Vector3(13.0, 0.0, 9.0)
	instance.add_child(isolated_oil)
	instance.add_child(diagonal_wall)
	await physics_frame
	player.health.reset_health()
	player.global_position = isolated_oil.global_position
	isolated_oil.apply_damage(4.0, player)
	_expect(not diagonal_wall.is_burning, "fire does not propagate across a diagonal gap")
	var health_before_fire := player.health.current_health
	isolated_oil.call("_physics_process", 1.0)
	_expect(is_equal_approx(player.health.current_health, health_before_fire - 1.0), "active fire deals one damage per second without faction rules")
	isolated_oil.call("_physics_process", 3.1)
	_expect(not isolated_oil.environment_active, "oil barrel disappears after four burning seconds")
	_expect(not navigation.is_world_position_blocked(Vector3(11.0, 0.0, 7.0)), "finished oil fire opens its navigation cell")
	_expect((isolated_oil.get_node("CollisionShape3D") as CollisionShape3D).disabled, "finished oil fire disables collision immediately")

	player.health.reset_health()
	guard.global_position = Vector3(20.0, 0.0, 15.0)
	player.global_position = Vector3(10.0, 0.0, -1.0)
	var snapshot_wall := wall_scene.instantiate() as DamageableWall
	snapshot_wall.position = Vector3(10.0, 0.0, 0.0)
	instance.add_child(snapshot_wall)
	await physics_frame
	snapshot_wall.apply_damage(3.0, player)
	reaction_hub.request_explosion(Vector3(10.0, 1.0, 1.0), 3.0, 3.0, 1.0, player)
	_expect(not snapshot_wall.environment_active, "explosion destroys a weakened blocking wood wall")
	_expect(is_equal_approx(player.health.current_health, player.health.max_health), "same explosion does not pass through the wall it destroys")

	player.health.reset_health()
	guard.health.reset_health()
	player.global_position = Vector3(15.0, 0.0, 10.0)
	guard.global_position = Vector3(18.0, 0.0, 10.0)
	reaction_hub.request_explosion(Vector3(15.0, 1.0, 10.0), 3.0, 3.0, 1.0, player)
	_expect(is_equal_approx(player.health.current_health, 2.0), "factionless explosion damages its player source at the center")
	_expect(is_equal_approx(guard.health.current_health, 2.0), "explosion edge deals one damage to guard")

	player.health.reset_health()
	guard.health.reset_health()
	player.global_position = Vector3(0.0, 0.0, -9.0)
	guard.global_position = Vector3(2.0, 0.0, -7.0)
	var occluded_gasoline := load("res://scenes/world/gasoline_barrel_wall.tscn").instantiate() as GasolineBarrelWall
	occluded_gasoline.position = Vector3(0.0, 0.0, -7.0)
	instance.add_child(occluded_gasoline)
	await physics_frame
	occluded_gasoline.apply_damage(3.0, player)
	_expect(is_equal_approx(player.health.current_health, player.health.max_health), "brick wall blocks gasoline explosion damage")
	_expect(guard.health.current_health < guard.health.max_health, "unoccluded guard takes gasoline explosion damage")
	instance.queue_free()
	await process_frame

func _test_main_scene() -> void:
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	_expect(scene != null, "main scene loads")
	if scene == null:
		return
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await physics_frame
	var debug_input := instance.get_node("DebugPlayerInput")
	debug_input.set_process(false)
	debug_input.set_process_unhandled_input(false)
	var player := instance.get_node_or_null("Player") as PlayerCharacter
	var guard := instance.get_node_or_null("PistolGuard") as PistolGuard
	_expect(player != null, "main scene contains player")
	_expect(guard != null, "main scene contains pistol guard")
	_expect(instance.get_node_or_null("Camera3D") is FixedFollowCamera, "main scene contains fixed camera")
	_expect(instance.get_tree().get_nodes_in_group("damageable_walls").size() == 5, "main scene contains five damageable wall modules")
	_expect(instance.get_node_or_null("EnvironmentReactionHub") is GameEnvironmentReactionHub, "main scene contains environment reaction hub")
	_expect(instance.get_node_or_null("OilBarrelWall") is OilBarrelWall, "main scene contains oil barrel wall")
	_expect(instance.get_node_or_null("GasolineBarrelWall") is GasolineBarrelWall, "main scene contains gasoline barrel wall")
	_expect(instance.get_node_or_null("ObjectivePoint") is GameObjectivePoint3D, "main scene contains remote objective point")
	_expect(instance.get_node_or_null("ExtractionPoint") is GameExtractionPoint3D, "main scene contains spawn extraction point")
	_expect(instance.get_node_or_null("MissionController") is GameMissionController, "main scene contains mission controller")
	_expect(instance.get_node_or_null("HUD/ObjectiveIndicator") is GameObjectiveIndicator, "HUD contains edge objective indicator")
	_expect(instance.get_node_or_null("HUD/TouchControls") is GameTouchInputRouter, "main scene contains touch input router")
	_expect(instance.get_node_or_null("HUD/TouchControls/MoveJoystick") is GameVirtualJoystick, "touch layout contains movement joystick")
	_expect(instance.get_node_or_null("HUD/TouchControls/AimJoystick") is GameVirtualJoystick, "touch layout contains aim joystick")
	_expect(instance.get_node_or_null("HUD/TouchControls/FireButton") is GameFireAimButton, "touch layout contains draggable fire button")
	if player != null and guard != null:
		guard.set_physics_process(false)
		player.global_position = Vector3(0.0, 0.0, 5.0)
		player.set_aim_input(Vector2(0.0, -1.0), true)
		guard.global_position = Vector3.ZERO
		guard.rotation.y = PI
		await physics_frame
		_expect(player.vision.can_see(guard), "player vision sees guard inside 120 degree cone")
		_expect(guard.vision.can_see(player), "guard vision uses symmetric range and angle")

		guard.global_position = Vector3(10.0, 0.0, 5.0)
		await physics_frame
		_expect(not player.vision.can_see(guard), "player vision rejects target outside cone angle")

		guard.global_position = Vector3(0.0, 0.0, -10.0)
		await physics_frame
		_expect(not player.vision.can_see(guard), "wall occludes target inside cone and range")

		guard.global_position = Vector3.ZERO
		guard.rotation.y = PI
		guard.set_physics_process(true)
		for _frame in 50:
			await physics_frame
		_expect(player.health.current_health < player.health.max_health, "guard warning ends in a damaging first shot")
		_expect(guard.exposure_remaining > 0.0, "guard attack starts two second exposure")

		guard.set_physics_process(false)
		player.set_aim_input(Vector2(0.0, 1.0), true)
		guard.call("_update_player_visibility")
		_expect(guard.visual_root.visible, "attack exposure reveals guard outside player cone")

		guard.global_position = Vector3(0.0, 0.0, -10.0)
		guard.call("_update_player_visibility")
		_expect(not guard.visual_root.visible, "attack exposure does not reveal through wall")
		_expect(guard.last_position_marker.visible, "wall crossing leaves static last exposed marker")

		guard.exposure_remaining = 0.0
		guard.call("_update_player_visibility")
		_expect(not guard.last_position_marker.visible, "last exposed marker expires with exposure")

		var wall := instance.get_node("WoodWallD") as DamageableWall
		player.global_position = Vector3(3.0, 0.0, 5.0)
		player.set_aim_input(Vector2(0.0, -1.0), true)
		await physics_frame
		_expect(player.request_fire(), "player can fire standard pistol")
		await physics_frame
		_expect(player.weapon.ammo_in_magazine == 5, "one shot consumes one round")
		_expect(is_equal_approx(wall.health.current_health, 4.0), "hitscan shot damages wood wall by one")
	instance.queue_free()
	await process_frame

func _test_weapon_pickups_and_rocket() -> void:
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await physics_frame
	var debug_input := instance.get_node("DebugPlayerInput")
	debug_input.set_process(false)
	debug_input.set_process_unhandled_input(false)
	var player := instance.get_node("Player") as PlayerCharacter
	var guard := instance.get_node("PistolGuard") as PistolGuard
	guard.set_physics_process(false)
	player.set_physics_process(false)
	var pickup_nodes := instance.get_tree().get_nodes_in_group("weapon_pickups")
	_expect(pickup_nodes.size() == 4, "main scene contains four special weapon pickups")
	_expect(instance.get_node_or_null("HUD/WeaponButtons/DefaultWeaponButton") is Button, "HUD contains default weapon switch button")
	_expect(instance.get_node_or_null("HUD/WeaponButtons/SpecialWeaponButton") is Button, "HUD contains special weapon switch button")
	_expect(instance.get_node_or_null("HUD/SwapWeaponButton") is Button, "HUD contains contextual weapon swap button")

	var heavy_pickup := instance.get_node("HeavyPistolPickup") as GameWeaponPickup3D
	_expect(heavy_pickup.collect_for_player(player), "empty special slot automatically collects weapon pickup")
	_expect(player.special_weapon != null and player.special_weapon.definition.weapon_id == &"heavy_pistol", "automatic pickup equips heavy pistol in special slot")
	_expect(player.default_weapon != null and player.default_weapon.definition.weapon_id == &"standard_pistol", "special pickup permanently preserves standard pistol")
	player.special_weapon.set_ammo_state(4, 7)

	var machine_pickup := instance.get_node("MachineGunPickup") as GameWeaponPickup3D
	_expect(not machine_pickup.collect_for_player(player), "different special weapon requires explicit confirmation")
	_expect((instance.get_node("HUD/SwapWeaponButton") as Button).visible, "different pickup exposes temporary swap button")
	_expect(player.confirm_weapon_swap(), "player can confirm offered special weapon exchange")
	_expect(player.special_weapon.definition.weapon_id == &"machine_gun", "confirmed exchange equips new special weapon")
	var touch_router := instance.get_node("HUD/TouchControls") as GameTouchInputRouter
	var automatic_ammo_before := player.special_weapon.ammo_in_magazine
	touch_router.set("_fire_held", true)
	touch_router.call("_process", 0.0)
	player.special_weapon.call("_physics_process", player.special_weapon.definition.shot_interval_seconds + 0.01)
	touch_router.call("_process", 0.0)
	touch_router.set("_fire_held", false)
	_expect(player.special_weapon.ammo_in_magazine == automatic_ammo_before - 2, "held touch fire repeatedly requests automatic machine-gun shots")
	var preserved_drop: GameWeaponPickup3D
	for pickup in instance.get_tree().get_nodes_in_group("weapon_pickups"):
		var candidate := pickup as GameWeaponPickup3D
		if candidate != null and candidate.definition.weapon_id == &"heavy_pistol" and candidate != heavy_pickup:
			preserved_drop = candidate
			break
	_expect(preserved_drop != null, "exchange drops replaced special weapon in the world")
	if preserved_drop != null:
		_expect(preserved_drop.stored_magazine == 4 and preserved_drop.stored_reserve == 7, "dropped weapon preserves magazine and reserve state")

	player.special_weapon.set_ammo_state(12, 10)
	var bonus_pickup := instance.get_node("BonusMachineGunPickup") as GameWeaponPickup3D
	_expect(bonus_pickup.collect_for_player(player), "same-type pickup automatically replenishes reserve")
	_expect(player.special_weapon.reserve_ammo == 58, "same-type pickup adds its configured reserve ammunition")
	var full_pickup_scene := load("res://scenes/world/weapon_pickup_3d.tscn") as PackedScene
	var full_pickup := full_pickup_scene.instantiate() as GameWeaponPickup3D
	full_pickup.definition = load("res://resources/weapons/machine_gun.tres") as WeaponDefinition
	full_pickup.stored_reserve = 12
	instance.add_child(full_pickup)
	player.special_weapon.set_ammo_state(12, player.special_weapon.definition.max_reserve_ammo)
	_expect(not full_pickup.collect_for_player(player), "full reserve does not consume same-type pickup")
	_expect(not full_pickup.is_queued_for_deletion(), "unneeded same-type pickup remains available")

	player.special_weapon.set_ammo_state(1, 0)
	player.special_weapon.call("_physics_process", player.special_weapon.definition.shot_interval_seconds + 0.01)
	player.switch_to_special_weapon()
	_expect(player.request_fire(), "special weapon fires its final available round")
	_expect(player.current_weapon_slot == PlayerCharacter.WeaponSlot.DEFAULT, "exhausted special weapon automatically switches back to standard pistol")
	_expect(player.special_weapon != null and not player.special_weapon.has_any_ammo(), "exhausted special weapon remains stored in its slot")

	var rocket_definition := load("res://resources/weapons/rocket_launcher.tres") as WeaponDefinition
	player.equip_special_weapon(rocket_definition, 1, 0)
	player.global_position = Vector3(24.0, 0.0, 14.0)
	player.set_aim_input(Vector2(0.0, -1.0), true)
	player.call("_update_aim_direction")
	guard.global_position = Vector3(player.weapon.global_position.x, 0.0, 6.0)
	guard.health.reset_health()
	var guard_depleted := [false]
	guard.health.depleted.connect(func(_source: Node) -> void:
		guard_depleted[0] = true
	)
	_expect(player.weapon is RocketWeapon, "rocket pickup equips projectile weapon implementation")
	_expect(player.request_fire(), "rocket launcher spawns a physical rocket")
	var spawned_rocket: GameRocketProjectile
	for child in instance.get_children():
		if child is GameRocketProjectile:
			spawned_rocket = child as GameRocketProjectile
			break
	_expect(spawned_rocket != null, "rocket shot creates visible projectile node")
	if spawned_rocket != null:
		_expect(is_equal_approx(spawned_rocket.maximum_distance_meters, 16.0), "rocket projectile inherits unified 16 meter range")
		_expect(is_equal_approx(spawned_rocket.explosion_radius_meters, 4.0), "rocket projectile inherits four meter blast radius")
	for _frame in 60:
		await physics_frame
		if guard_depleted[0]:
			break
	_expect(guard_depleted[0], "rocket collision resolves factionless center explosion damage")
	_expect(player.current_weapon_slot == PlayerCharacter.WeaponSlot.DEFAULT, "empty rocket launcher returns control to default pistol while projectile travels")
	_weapon_integration_completed = true
	instance.queue_free()
	await process_frame

func _test_mission_loop() -> void:
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await physics_frame
	var debug_input := instance.get_node("DebugPlayerInput")
	debug_input.set_process(false)
	debug_input.set_process_unhandled_input(false)
	var player := instance.get_node("Player") as PlayerCharacter
	var guard := instance.get_node("PistolGuard") as PistolGuard
	var objective := instance.get_node("ObjectivePoint") as GameObjectivePoint3D
	var extraction := instance.get_node("ExtractionPoint") as GameExtractionPoint3D
	var mission := instance.get_node("MissionController") as GameMissionController
	guard.set_physics_process(false)
	player.set_physics_process(false)
	_expect(mission.current_phase == GameMissionController.MissionPhase.INFILTRATION, "mission starts in objective infiltration phase")
	_expect(not extraction.extraction_enabled, "spawn extraction is disabled before objective activation")
	extraction.call("_on_body_entered", player)
	_expect(mission.current_phase == GameMissionController.MissionPhase.INFILTRATION, "entering disabled extraction cannot complete mission")
	_expect(objective.global_position.distance_to(extraction.global_position) >= 36.0, "remote objective is at least eighteen two-meter modules from spawn")
	_expect(mission.get_current_target() == objective, "objective indicator initially targets remote objective")
	_expect(mission.get_distance_band(objective.global_position.distance_to(player.global_position)) == "远", "remote objective uses approximate far distance band")
	var objective_indicator := instance.get_node("HUD/ObjectiveIndicator") as GameObjectiveIndicator
	objective_indicator.call("_process", 0.0)
	_expect((objective_indicator.get_node("Marker/Status") as Label).text == "任务 · 远", "edge indicator labels remote mission target")
	_expect(mission.remaining_guards == 1, "mission tracks initial remaining guard count")
	_expect((instance.get_node("HUD/StatusPanel/Margin/Rows/EnemyCountLabel") as Label).text == "剩余警卫：1", "HUD displays remaining enemy count as threat reference")

	player.global_position = objective.global_position
	await physics_frame
	objective.call("_on_body_entered", player)
	objective.call("_physics_process", 1.0)
	_expect(is_equal_approx(objective.activation_elapsed, 1.0), "objective accumulates activation progress while player remains inside")
	_expect((instance.get_node("HUD/ActivationProgress") as ProgressBar).visible, "HUD displays objective activation progress")
	var progress_before_damage := objective.activation_elapsed
	player.apply_damage(1.0, guard)
	objective.call("_physics_process", 0.5)
	_expect(is_equal_approx(objective.activation_elapsed, progress_before_damage + 0.5), "taking damage does not reset objective activation")
	objective.call("_on_body_exited", player)
	_expect(is_zero_approx(objective.activation_elapsed), "leaving objective range resets activation progress")
	_expect(not (instance.get_node("HUD/ActivationProgress") as ProgressBar).visible, "reset progress hides activation bar")

	objective.call("_on_body_entered", player)
	objective.call("_physics_process", objective.activation_seconds)
	_expect(objective.is_activated, "remaining in objective range for three seconds activates mission point")
	_expect(mission.current_phase == GameMissionController.MissionPhase.EXTRACTION, "objective activation enters extraction phase")
	_expect(extraction.extraction_enabled, "objective activation enables spawn extraction")
	_expect(mission.get_current_target() == extraction, "objective indicator switches to spawn extraction")
	_expect(guard.current_state == PistolGuard.GuardState.INVESTIGATE, "objective alarm sends surviving guard to investigate")
	var guard_alarm_target: Vector3 = guard.get("_last_known_player_position")
	_expect(guard_alarm_target.is_equal_approx(objective.global_position), "global alarm reveals only objective position to guard")
	player.global_position += Vector3(4.0, 0.0, 0.0)
	var retained_alarm_target: Vector3 = guard.get("_last_known_player_position")
	_expect(retained_alarm_target.is_equal_approx(objective.global_position), "objective alarm does not continuously reveal player position")

	player.global_position = extraction.global_position
	extraction.call("_on_body_entered", player)
	_expect(mission.current_phase == GameMissionController.MissionPhase.WON, "entering enabled spawn extraction wins immediately")
	_expect(mission.remaining_guards == 1, "mission can be won without eliminating final guard")
	_expect(not player.controls_enabled and not player.request_fire(), "successful extraction disables further player control and firing")
	_expect((instance.get_node("HUD/ResultPanel") as PanelContainer).visible, "successful extraction opens result summary")
	_expect((instance.get_node("HUD/ResultPanel/Margin/Rows/ResultTitle") as Label).text == "撤离成功", "result summary reports successful extraction")
	instance.queue_free()
	await process_frame

	var failure_instance := scene.instantiate()
	root.add_child(failure_instance)
	await process_frame
	await physics_frame
	var failure_input := failure_instance.get_node("DebugPlayerInput")
	failure_input.set_process(false)
	failure_input.set_process_unhandled_input(false)
	var failure_player := failure_instance.get_node("Player") as PlayerCharacter
	var failure_guard := failure_instance.get_node("PistolGuard") as PistolGuard
	var failure_mission := failure_instance.get_node("MissionController") as GameMissionController
	failure_guard.set_physics_process(false)
	failure_player.set_physics_process(false)
	failure_guard.apply_damage(failure_guard.health.max_health, failure_player)
	_expect(failure_mission.remaining_guards == 0 and failure_mission.kills == 1, "guard death immediately updates remaining count and kill statistic")
	failure_player.apply_damage(failure_player.health.max_health, failure_guard)
	_expect(failure_mission.current_phase == GameMissionController.MissionPhase.FAILED, "player death immediately fails active mission")
	_expect(not failure_player.controls_enabled, "mission failure disables further player control")
	_expect((failure_instance.get_node("HUD/ResultPanel") as PanelContainer).visible, "mission failure opens result summary")
	_expect((failure_instance.get_node("HUD/ResultPanel/Margin/Rows/ResultTitle") as Label).text == "任务失败", "failure summary reports incomplete extraction")
	_mission_integration_completed = true
	failure_instance.queue_free()
	await process_frame

func _test_sound_investigation() -> void:
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await physics_frame
	var debug_input := instance.get_node("DebugPlayerInput")
	debug_input.set_process(false)
	debug_input.set_process_unhandled_input(false)
	var player := instance.get_node("Player") as PlayerCharacter
	var guard := instance.get_node("PistolGuard") as PistolGuard
	var sound_hub := instance.get_node("SoundEventHub") as GameSoundEventHub
	guard.set_physics_process(false)
	player.global_position = Vector3(0.0, 0.0, 5.0)
	guard.global_position = Vector3(10.0, 0.0, 5.0)
	guard.current_state = PistolGuard.GuardState.PATROL
	_expect(player.request_fire(), "player fires to emit standard pistol sound")
	_expect(guard.current_state == PistolGuard.GuardState.INVESTIGATE, "guard investigates gunshot inside 12 module hearing radius")

	guard.current_state = PistolGuard.GuardState.PATROL
	guard.global_position = Vector3(30.0, 0.0, 5.0)
	sound_hub.emit_sound_event(
		player.global_position,
		24.0,
		GameSoundEventHub.Priority.GUNSHOT,
		player
	)
	_expect(guard.current_state == PistolGuard.GuardState.PATROL, "guard ignores gunshot outside hearing radius")
	instance.queue_free()
	await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
