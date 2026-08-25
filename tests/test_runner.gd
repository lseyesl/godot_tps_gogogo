extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_weapon_definition()
	_test_health_component()
	await _test_navigation_grid()
	await _test_cover_behavior()
	await _test_main_scene()
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
	guard.call("_apply_fallback_combat_movement")
	var toward_band_player := (player.global_position - guard.global_position).normalized()
	_expect(absf(guard.velocity.dot(toward_band_player)) < 0.01, "guard strafes laterally inside preferred distance band")
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
	_expect(instance.get_tree().get_nodes_in_group("damageable_walls").size() == 4, "main scene contains four damageable wall modules")
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
