extends SceneTree

var _failures: Array[String] = []
var _weapon_integration_completed := false
var _mission_integration_completed := false
var _layout_integration_completed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_android_build_configuration()
	_test_touch_movement_response()
	_test_weapon_definition()
	await _test_weapon_runtime()
	_test_health_component()
	await _test_random_layout_and_health()
	_expect(_layout_integration_completed, "random layout integration test completes without runtime errors")
	await _test_navigation_grid()
	await _test_cover_behavior()
	await _test_environment_reactions()
	await _test_main_scene()
	await _test_aim_assist_and_blind_visibility()
	await _test_mission_loop()
	_expect(_mission_integration_completed, "mission integration test completes without runtime errors")
	await _test_weapon_pickups_and_rocket()
	_expect(_weapon_integration_completed, "weapon pickup and rocket integration test completes without runtime errors")
	await _test_audio_playback()
	await _test_sound_investigation()
	if _failures.is_empty():
		print("PASS: core slice tests")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

func _test_android_build_configuration() -> void:
	var preset := FileAccess.get_file_as_string("res://export_presets.cfg")
	var project := FileAccess.get_file_as_string("res://project.godot")
	var workflow := FileAccess.get_file_as_string("res://.github/workflows/android-build.yml")
	_expect(preset.contains('name="Android"'), "Android export preset has the CI preset name")
	_expect(preset.contains('platform="Android"'), "Android export preset selects the Android platform")
	_expect(preset.contains('architectures/arm64-v8a=true'), "Android export preset includes arm64")
	_expect(preset.contains('architectures/armeabi-v7a=false'), "Android export preset excludes legacy armv7")
	_expect(preset.contains("gradle_build/use_gradle_build=false"), "Android export uses the standard build path")
	_expect(preset.contains('gradle_build/min_sdk=""'), "Android standard export leaves Min SDK at the template default")
	_expect(preset.contains('gradle_build/target_sdk=""'), "Android standard export leaves Target SDK at the template default")
	var uses_standard_android_export := preset.contains("gradle_build/use_gradle_build=false")
	var leaves_sdk_defaults := preset.contains('gradle_build/min_sdk=""') and preset.contains('gradle_build/target_sdk=""')
	_expect(not uses_standard_android_export or leaves_sdk_defaults, "Android SDK overrides require Gradle build mode")
	_expect(project.contains("textures/vram_compression/import_etc2_astc=true"), "Android export enables required ETC2/ASTC texture compression")
	_expect(workflow.contains("barichello/godot-ci:4.7"), "Android workflow uses the matching Godot CI image")
	_expect(workflow.contains("  workflow_dispatch:"), "Android workflow supports manual dispatch")
	_expect(workflow.contains("      tag:"), "Android workflow requires a release tag input")
	_expect(workflow.contains("      prerelease:"), "Android workflow exposes a prerelease input")
	_expect(not workflow.contains("\n  push:"), "Android workflow does not run on repository pushes")
	_expect(not workflow.contains("\n  pull_request:"), "Android workflow does not run on pull requests")
	_expect(workflow.contains("  contents: write"), "Android workflow can create repository releases")
	_expect(workflow.contains("editor_settings-${GODOT_VERSION}.tres"), "Android workflow copies the versioned Godot 4.7 editor settings")
	_expect(workflow.contains("JAVA_HOME: /usr/lib/jvm/java-17-openjdk-amd64"), "Android workflow exposes the Java SDK path")
	_expect(workflow.contains("ANDROID_HOME: /usr/lib/android-sdk"), "Android workflow exposes the Android SDK path")
	_expect(workflow.contains("apt-get install -y --no-install-recommends fontconfig"), "Android workflow installs the missing fontconfig runtime")
	_expect(workflow.contains('test -x "${JAVA_HOME}/bin/java"'), "Android workflow fails early when Java is unavailable")
	_expect(workflow.contains("--script res://tests/test_runner.gd"), "Android workflow runs core regression tests before export")
	_expect(workflow.contains("--export-debug Android"), "Android workflow exports the configured debug APK")
	_expect(workflow.contains('^v?[0-9]+\\.[0-9]+\\.[0-9]+'), "Android workflow validates the release tag format")
	_expect(workflow.contains("softprops/action-gh-release@v2"), "Android workflow publishes a GitHub Release")
	_expect(workflow.contains("tag_name: ${{ inputs.tag }}"), "Android workflow publishes under the requested tag")
	_expect(workflow.contains("generate_release_notes: true"), "Android workflow generates release notes")
	_expect(workflow.contains("files: ${{ env.APK_PATH }}"), "Android workflow attaches the APK to the release")
	_expect(not workflow.contains("actions/upload-artifact@v4"), "Android workflow does not retain a duplicate temporary artifact")

func _test_touch_movement_response() -> void:
	var joystick := GameVirtualJoystick.new()
	joystick.size = Vector2(160.0, 160.0)
	root.add_child(joystick)
	joystick.call("_update_value", joystick.size * 0.5 + Vector2(joystick.movement_radius * 0.5, 0.0))
	_expect(joystick.value.length() >= 0.62, "half joystick drag produces responsive movement output")
	joystick.call("_update_value", joystick.size * 0.5 + Vector2(joystick.movement_radius, 0.0))
	_expect(is_equal_approx(joystick.value.length(), 1.0), "full joystick drag reaches maximum movement output")
	joystick.call("_update_value", joystick.size * 0.5 + Vector2(joystick.movement_radius * 0.08, 0.0))
	_expect(joystick.value == Vector2.ZERO, "small joystick drift remains inside the deadzone")
	joystick.queue_free()

func _test_weapon_definition() -> void:
	var definition := load("res://resources/weapons/standard_pistol.tres") as WeaponDefinition
	_expect(definition != null, "standard pistol resource loads")
	if definition == null:
		return
	_expect(definition.is_valid(), "standard pistol resource is valid")
	_expect(is_equal_approx(definition.damage, 1.0), "standard pistol damage is 1")
	_expect(is_equal_approx(definition.range_meters, 8.0), "standard pistol range is 8 meters")
	_expect(definition.muzzle_position.is_equal_approx(Vector3(0.13, 1.29, -0.35)), "standard pistol stores its model-aligned muzzle position")
	_expect(definition.magazine_capacity == 6, "standard pistol magazine is 6")
	_expect(is_equal_approx(definition.sound_radius_meters, 24.0), "standard pistol sound radius is 12 modules")
	var heavy := load("res://resources/weapons/heavy_pistol.tres") as WeaponDefinition
	var machine_gun := load("res://resources/weapons/machine_gun.tres") as WeaponDefinition
	var rocket := load("res://resources/weapons/rocket_launcher.tres") as WeaponDefinition
	_expect(heavy != null and heavy.is_valid(), "heavy pistol resource is valid")
	_expect(heavy.damage == 2.0 and heavy.magazine_capacity == 6, "heavy pistol uses frozen damage and magazine values")
	_expect(heavy.muzzle_position.is_equal_approx(definition.muzzle_position), "heavy pistol uses the complete pistol miniature muzzle")
	_expect(not heavy.infinite_reserve and heavy.starting_reserve_ammo == 18, "heavy pistol starts with finite 18-round reserve")
	_expect(machine_gun != null and machine_gun.is_valid(), "machine gun resource is valid")
	_expect(machine_gun.automatic and is_equal_approx(machine_gun.shot_interval_seconds, 0.1), "machine gun supports held fire at ten rounds per second")
	_expect(machine_gun.magazine_capacity == 24 and machine_gun.starting_reserve_ammo == 48, "machine gun uses frozen ammunition values")
	_expect(machine_gun.muzzle_position.is_equal_approx(Vector3(0.12, 1.17, -0.24)), "machine gun stores its model-aligned muzzle position")
	_expect(rocket != null and rocket.is_valid(), "rocket launcher resource is valid")
	_expect(rocket.muzzle_position.is_equal_approx(Vector3(0.17, 1.43, -0.76)), "rocket launcher stores its model-aligned muzzle position")
	for weapon_definition in [definition, heavy, machine_gun, rocket]:
		_expect(is_equal_approx(weapon_definition.range_meters, 8.0), "all player and guard weapons use the unified 8 meter CQB range")
		_expect(weapon_definition.range_meters < 10.0, "weapon range remains shorter than player vision")
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

func _test_random_layout_and_health() -> void:
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var run_state := root.get_node("GameRunState")
	run_state.call("begin_new_game_with_seed", 1357911)
	var first_instance := scene.instantiate()
	root.add_child(first_instance)
	await process_frame
	await physics_frame
	var first_input := first_instance.get_node("DebugPlayerInput")
	first_input.set_process(false)
	first_input.set_process_unhandled_input(false)
	_disable_all_guards(first_instance)
	var player := first_instance.get_node("Player") as PlayerCharacter
	player.set_physics_process(false)
	var spawner := first_instance.get_node("ContentSpawner3D") as GameContentSpawner3D
	var first_signature: Dictionary = spawner.layout_signature.duplicate(true)
	var guards := _nodes_in_group_under(first_instance, &"guards")
	var weapons := _nodes_in_group_under(first_instance, &"weapon_pickups")
	var health_packs := _nodes_in_group_under(first_instance, &"health_pickups")
	var objective := first_instance.get_node("ContentSpawner3D/ObjectivePoint") as GameObjectivePoint3D
	var extraction := first_instance.get_node("ExtractionPoint") as GameExtractionPoint3D
	_expect(spawner.layout_seed == 1357911, "content spawner consumes active run seed")
	_expect(guards.size() >= 8 and guards.size() <= 12, "seeded layout preplaces eight to twelve guards")
	_expect(weapons.size() == 4, "seeded layout creates exactly four special weapons")
	_expect(health_packs.size() == 2, "seeded layout creates exactly two health packs")
	_expect(objective.global_position.distance_to(extraction.global_position) >= 36.0, "seeded objective candidate remains at least eighteen modules from spawn")

	var guard_candidates := first_instance.get_node("ContentCandidates/GuardCandidates")
	var obstacle_count := _nodes_in_group_under(first_instance, &"navigation_obstacles").size()
	_expect(obstacle_count >= 60, "room-first CQB map provides enough structural and micro-cover obstacles")
	var navigation := first_instance.get_node("GridNavigation3D") as GameGridNavigation3D
	for container_path in [
		"ContentCandidates/GuardCandidates",
		"ContentCandidates/ObjectiveCandidates",
		"ContentCandidates/WeaponCandidates",
		"ContentCandidates/HealthCandidates",
	]:
		var candidate_container := first_instance.get_node(container_path)
		for candidate_node in candidate_container.get_children():
			var candidate := candidate_node as Marker3D
			_expect(not navigation.get_world_path(player.global_position, candidate.global_position).is_empty(), "%s remains reachable through the room-and-corridor loops" % candidate.name)
	var exposure := await _measure_authored_guard_exposure(first_instance, player, guard_candidates)
	_expect(exposure.spawn_count == 0, "no authored guard candidate can see the player at spawn")
	_expect(exposure.maximum_count <= 2, "opening route exposes the player to at most two authored guards at once")
	var no_guard_starts_visible := true
	for node in guards:
		var guard := node as PistolGuard
		if not _position_is_candidate(guard, guard_candidates) or player.vision.can_see(guard):
			no_guard_starts_visible = false
	_expect(no_guard_starts_visible, "all guards use validated candidates outside spawn direct vision")
	_expect(_position_is_candidate(objective, first_instance.get_node("ContentCandidates/ObjectiveCandidates")), "objective uses authored candidate position")

	var weapon_counts := {
		&"heavy_pistol": 0,
		&"machine_gun": 0,
		&"rocket_launcher": 0,
	}
	var all_weapons_on_candidates := true
	for node in weapons:
		var pickup := node as GameWeaponPickup3D
		weapon_counts[pickup.definition.weapon_id] += 1
		all_weapons_on_candidates = all_weapons_on_candidates and _position_is_candidate(
			pickup,
			first_instance.get_node("ContentCandidates/WeaponCandidates")
		)
		pickup.call("_process", 0.0)
		_expect(pickup.visible == player.vision.can_see(pickup), "weapon pickup visibility follows player cone and wall occlusion")
	_expect(weapon_counts[&"heavy_pistol"] >= 1, "weapon budget guarantees heavy pistol")
	_expect(weapon_counts[&"machine_gun"] >= 1, "weapon budget guarantees machine gun")
	_expect(weapon_counts[&"rocket_launcher"] >= 1, "weapon budget guarantees rocket launcher")
	_expect(all_weapons_on_candidates, "all weapons use authored candidate positions")

	var health_candidates := first_instance.get_node("ContentCandidates/HealthCandidates")
	for node in health_packs:
		var candidate_pack := node as GameHealthPack3D
		_expect(_position_is_candidate(candidate_pack, health_candidates), "health pack uses authored candidate position")
		candidate_pack.call("_process", 0.0)
		_expect(candidate_pack.get_node("VisualRoot").visible == player.vision.can_see(candidate_pack), "health pack visibility follows player cone and wall occlusion")
	var health_pack := health_packs[0] as GameHealthPack3D
	_expect(not health_pack.collect_for_player(player), "full-health player does not consume health pack")
	_expect(not health_pack.is_queued_for_deletion(), "unused full-health pack remains in world")
	player.apply_damage(3.0)
	_expect(health_pack.collect_for_player(player), "injured player automatically consumes health pack")
	_expect(is_equal_approx(player.health.current_health, 4.0), "health pack restores two points without exceeding maximum")

	first_instance.queue_free()
	await process_frame
	_expect(int(run_state.call("retry_current_game")) == 1357911, "retry retains active run seed")
	var retry_instance := scene.instantiate()
	root.add_child(retry_instance)
	await process_frame
	await physics_frame
	var retry_signature: Dictionary = (retry_instance.get_node("ContentSpawner3D") as GameContentSpawner3D).layout_signature.duplicate(true)
	_expect(retry_signature == first_signature, "retry seed reconstructs identical guards, objective, weapons and health layout")
	_expect(_nodes_in_group_under(retry_instance, &"health_pickups").size() == 2, "retry restores consumed health packs")
	_expect(is_equal_approx((retry_instance.get_node("Player") as PlayerCharacter).health.current_health, 5.0), "retry restores player health to initial state")
	retry_instance.queue_free()
	await process_frame

	run_state.call("begin_new_game_with_seed", 2468022)
	var new_game_instance := scene.instantiate()
	root.add_child(new_game_instance)
	await process_frame
	await physics_frame
	var new_signature: Dictionary = (new_game_instance.get_node("ContentSpawner3D") as GameContentSpawner3D).layout_signature.duplicate(true)
	_expect(new_signature != first_signature, "new game seed creates a different content layout")
	_expect(new_game_instance.get_node_or_null("HUD/ResultPanel/Margin/Rows/Actions/RetryButton") is Button, "failure result provides retry action")
	_expect(new_game_instance.get_node_or_null("HUD/ResultPanel/Margin/Rows/Actions/NewGameButton") is Button, "result provides new-game action")
	_layout_integration_completed = true
	new_game_instance.queue_free()
	await process_frame
	run_state.call("begin_new_game_with_seed", 97531)

func _measure_authored_guard_exposure(instance: Node3D, player: PlayerCharacter, candidates: Node) -> Dictionary:
	var guard_scene := load("res://scenes/actors/pistol_guard.tscn") as PackedScene
	var probes: Array[PistolGuard] = []
	for marker_node in candidates.get_children():
		var marker := marker_node as Marker3D
		var probe := guard_scene.instantiate() as PistolGuard
		instance.add_child(probe)
		probe.global_transform = marker.global_transform
		probe.set_physics_process(false)
		probes.append(probe)
	await physics_frame
	var original_position := player.global_position
	var sample_positions: Array[Vector3] = [
		Vector3(0.0, 0.0, 5.0),
		Vector3(0.0, 0.0, 1.0),
		Vector3(-5.0, 0.0, -2.0),
		Vector3(5.0, 0.0, -2.0),
	]
	var counts := PackedInt32Array()
	var maximum_count := 0
	for position in sample_positions:
		player.global_position = position
		await physics_frame
		var visible_count := 0
		for probe in probes:
			if probe.vision.can_see(player):
				visible_count += 1
		counts.append(visible_count)
		maximum_count = maxi(maximum_count, visible_count)
	player.global_position = original_position
	for probe in probes:
		probe.queue_free()
	await process_frame
	return {"spawn_count": counts[0], "maximum_count": maximum_count, "counts": counts}

func _test_navigation_grid() -> void:
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	var debug_input := instance.get_node("DebugPlayerInput")
	debug_input.set_process(false)
	debug_input.set_process_unhandled_input(false)
	var guard := instance.get_node("ContentSpawner3D/PistolGuard") as PistolGuard
	_disable_all_guards(instance)
	var navigation := instance.get_node("GridNavigation3D") as GameGridNavigation3D
	var wall := instance.get_node("WoodWallD") as DamageableWall
	_expect(navigation != null, "main scene contains 2D grid navigation")
	_expect(navigation.is_world_position_blocked(Vector3(-25.0, 0.0, 1.0)), "indestructible room threshold blocks overlapping navigation cells")
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
	var guard := instance.get_node("ContentSpawner3D/PistolGuard") as PistolGuard
	var cover_service := instance.get_node("CoverService3D") as GameCoverService3D
	_disable_all_guards(instance)
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
		_expect(guard.current_state == PistolGuard.GuardState.MOVE_TO_COVER, "guard leaves destroyed cover for a replacement CQB partition")
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
	player.global_position = Vector3(0.0, 0.0, 8.0)
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
	var guard := instance.get_node("ContentSpawner3D/PistolGuard") as PistolGuard
	var navigation := instance.get_node("GridNavigation3D") as GameGridNavigation3D
	var reaction_hub := instance.get_node("EnvironmentReactionHub") as GameEnvironmentReactionHub
	var oil := instance.get_node("OilBarrelWall") as OilBarrelWall
	var burnable_wood := instance.get_node("BurnableWoodWall") as DamageableWall
	var gasoline := instance.get_node("GasolineBarrelWall") as GasolineBarrelWall
	var oil_health_bar := oil.get_node("HealthBar3D") as GameWorldHealthBar3D
	var gasoline_health_bar := gasoline.get_node("HealthBar3D") as GameWorldHealthBar3D
	_disable_all_guards(instance)
	player.set_physics_process(false)
	_expect(is_equal_approx(oil.health.max_health, 4.0), "oil barrel durability is four")
	_expect(is_equal_approx(gasoline.health.max_health, 3.0), "gasoline barrel durability is three")
	_expect(not oil_health_bar.visible and not gasoline_health_bar.visible, "destructible health bars stay hidden before damage")
	_expect(navigation.is_world_position_blocked(oil.global_position), "intact oil barrel blocks navigation")
	oil.apply_damage(1.0, player)
	_expect(oil_health_bar.visible and is_equal_approx(oil_health_bar.fill_ratio, 0.75), "oil barrel damage reveals its matching remaining health")
	oil_health_bar.call("_process", oil_health_bar.display_seconds + 0.1)
	_expect(not oil_health_bar.visible, "destructible health bar hides after its feedback window")
	gasoline.apply_damage(1.0, player)
	_expect(gasoline_health_bar.visible and is_equal_approx(gasoline_health_bar.fill_ratio, 2.0 / 3.0), "gasoline damage reveals its matching remaining health")
	oil.apply_damage(3.0, player)
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
	var wall_health_bar := snapshot_wall.get_node("HealthBar3D") as GameWorldHealthBar3D
	_expect(wall_health_bar.visible and is_equal_approx(wall_health_bar.fill_ratio, 0.4), "wood wall damage reveals its matching remaining health")
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
	var navigation := instance.get_node("GridNavigation3D") as GameGridNavigation3D
	var player := instance.get_node_or_null("Player") as PlayerCharacter
	var guard := instance.get_node_or_null("ContentSpawner3D/PistolGuard") as PistolGuard
	_expect(player != null, "main scene contains player")
	_expect(is_equal_approx(player.move_speed, 5.0), "player moves at five meters per second")
	_expect(player.get_node_or_null("ShotFeedback3D") is GameShotFeedback3D, "player contains reusable shot feedback")
	_expect(player.get_node_or_null("DamageFeedback3D") is GameDamageFeedback3D, "player contains damage feedback")
	var player_miniature := player.get_node_or_null("VisualRoot/PlayerMiniature") as GameMiniatureVisual3D
	_expect(player_miniature != null, "player uses the shared GLB miniature prefab")
	var rifle_miniature := player.get_node_or_null("VisualRoot/PlayerRifleMiniature") as GameMiniatureVisual3D
	var rocket_miniature := player.get_node_or_null("VisualRoot/PlayerRocketMiniature") as GameMiniatureVisual3D
	_expect(rifle_miniature != null and rocket_miniature != null, "player includes complete rifle and rocket miniature variants")
	_expect(player_miniature.visible and not rifle_miniature.visible and not rocket_miniature.visible, "player initially shows only the pistol miniature")
	_expect(player.to_local(player.weapon.global_position).is_equal_approx(player.weapon.definition.muzzle_position), "player bullet origin aligns with the visible pistol muzzle")
	_expect(player.get_node_or_null("BodyMesh") == null, "player primitive preview body is removed")
	if player_miniature != null:
		var imported_model := player_miniature.get_node_or_null("ImportedModel") as Node3D
		_expect(imported_model != null, "shared miniature contains the imported model")
		if imported_model != null:
			_expect(imported_model.scale.is_equal_approx(Vector3.ONE * 1.8), "shared miniature fills the actor collision height")
			_expect(is_equal_approx(imported_model.position.y, 0.9), "enlarged miniature remains grounded")
			_expect(is_equal_approx(imported_model.rotation.y, PI), "shared miniature faces the same forward direction as actor gameplay")
	_expect(guard != null, "main scene contains pistol guard")
	_expect(guard.to_local(guard.weapon.global_position).is_equal_approx(guard.weapon.definition.muzzle_position), "guard bullet origin aligns with the visible pistol muzzle")
	_expect(guard.get_node_or_null("DamageFeedback3D") is GameDamageFeedback3D, "guard contains damage feedback")
	var enemy_miniature := guard.get_node_or_null("VisualRoot/EnemyMiniature") as GameMiniatureVisual3D
	_expect(enemy_miniature != null, "guard uses the shared GLB miniature prefab")
	_expect(guard.get_node_or_null("VisualRoot/BodyMesh") == null, "guard primitive preview body is removed")
	if player_miniature != null and enemy_miniature != null:
		_expect(player_miniature.faction_color != enemy_miniature.faction_color, "shared miniature instances use distinct faction colors")
		_expect(player_miniature.faction_color.is_equal_approx(Color(0.08, 0.48, 0.46, 1.0)), "player uses the concept-art dark teal armor color")
		_expect(enemy_miniature.faction_color.is_equal_approx(Color(0.55, 0.16, 0.14, 1.0)), "guards use the concept-art dark red armor color")
		for miniature in [player_miniature, enemy_miniature]:
			var current_miniature := miniature as GameMiniatureVisual3D
			var meshes: Array[Node] = current_miniature.find_children("*", "MeshInstance3D", true, false)
			_expect(not meshes.is_empty(), "%s contains a tintable imported mesh" % current_miniature.name)
			if not meshes.is_empty():
				var miniature_mesh := meshes[0] as MeshInstance3D
				var miniature_material := miniature_mesh.material_override as ShaderMaterial
				_expect(miniature_material != null, "%s uses the texture-preserving faction shader" % current_miniature.name)
				if miniature_material != null:
					_expect(miniature_material.get_shader_parameter("has_albedo_texture") == true, "%s preserves the imported armor, visor, and weapon texture" % current_miniature.name)
					_expect(miniature_material.get_shader_parameter("faction_color") == current_miniature.faction_color, "%s applies its concept-art faction color" % current_miniature.name)
				_expect(miniature_mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "%s does not cast dynamic character shadows" % current_miniature.name)
	var camera := instance.get_node_or_null("Camera3D") as FixedFollowCamera
	_expect(camera != null, "main scene contains fixed camera")
	if camera != null:
		_expect(camera.offset.is_equal_approx(Vector3(0.0, 10.5, 7.5)), "fixed camera uses the tighter CQB framing")
	_expect(is_equal_approx(player.vision.view_distance, 10.0), "player uses the reduced 10 meter CQB vision distance")
	_expect(is_equal_approx(guard.vision.view_distance, 8.0), "guards use the reduced 8 meter CQB vision distance")
	_expect(is_equal_approx(guard.weapon.definition.range_meters, guard.vision.view_distance), "guard attack range matches guard vision distance")
	_expect((player.get_node("VisionCone3D") as GameVisionCone3D).ray_count == 128, "vision cone uses enough cached rays for stable occlusion edges while rotating")
	var floor_mesh := instance.get_node_or_null("Floor") as MeshInstance3D
	_expect(floor_mesh != null, "main scene contains the assembled ground surface")
	if floor_mesh != null:
		_expect(floor_mesh.position.y <= -0.02, "ground renders below actor bases instead of competing at the same depth")
		var floor_material := floor_mesh.material_override as ShaderMaterial
		_expect(floor_material != null, "ground uses the tile assembly shader")
		if floor_material != null:
			var ground_shader_source := FileAccess.get_file_as_string("res://shaders/ground_tile_assembly.gdshader")
			_expect(not ground_shader_source.contains("ALPHA ="), "opaque ground cannot cover the transparent vision cone in the render queue")
			_expect(floor_material.get_shader_parameter("concrete_texture") != null, "ground assembly includes the concrete concept tile")
			_expect(floor_material.get_shader_parameter("drainage_texture") != null, "ground assembly includes the drainage concept tile")
			_expect(floor_material.get_shader_parameter("armored_steel_texture") != null, "ground assembly includes the armored-steel concept tile")
			_expect(floor_material.get_shader_parameter("tile_count") == Vector2(15.0, 10.0), "four-meter ground modules align with the two-meter navigation grid")
	var north_boundary := instance.get_node_or_null("NorthBoundaryWall") as StaticBody3D
	var south_boundary := instance.get_node_or_null("SouthBoundaryWall") as StaticBody3D
	var west_boundary := instance.get_node_or_null("WestBoundaryWall") as StaticBody3D
	var east_boundary := instance.get_node_or_null("EastBoundaryWall") as StaticBody3D
	_expect(north_boundary != null and south_boundary != null, "map has brick walls across both horizontal boundaries")
	_expect(west_boundary != null and east_boundary != null, "map has brick walls across both vertical boundaries")
	if north_boundary != null and south_boundary != null:
		_expect(north_boundary.call("get_module_count") == 30 and south_boundary.call("get_module_count") == 30, "horizontal boundaries each contain thirty brick modules")
		_expect(north_boundary.get_node("VisualRoot").get_child_count() == 30, "north boundary builds all imported brick visuals")
	if west_boundary != null and east_boundary != null:
		_expect(west_boundary.call("get_module_count") == 20 and east_boundary.call("get_module_count") == 20, "vertical boundaries each contain twenty brick modules")
		_expect(west_boundary.get_node("VisualRoot").get_child_count() == 20, "west boundary builds all imported brick visuals")
	for boundary in [north_boundary, south_boundary, west_boundary, east_boundary]:
		if boundary != null:
			_expect(boundary.is_in_group("static_visibility"), "%s blocks line of sight" % boundary.name)
			_expect(boundary.get_node_or_null("CollisionShape3D") is CollisionShape3D, "%s has physical collision" % boundary.name)
	_expect(_nodes_in_group_under(instance, &"damageable_walls").size() == 23, "main scene contains twenty-three damageable wall modules")
	_expect(instance.get_node_or_null("SpawnRearWall") is StaticBody3D, "spawn courtyard has indestructible rear cover")
	_expect(instance.get_node_or_null("SpawnLeftWall") is StaticBody3D, "spawn courtyard has indestructible left cover")
	_expect(instance.get_node_or_null("SpawnRightWall") is StaticBody3D, "spawn courtyard has indestructible right cover")
	var room_layout := instance.get_node_or_null("CQBRoomLayout3D") as Node3D
	_expect(room_layout != null, "main scene contains the dedicated room-first CQB layout")
	_expect(instance.get_node_or_null("CQBRoomLayout3D/NorthThreshold01/VisualRoot/Module01/Model/world/geometry_0") is MeshInstance3D, "room walls use repeated imported brick modules")
	_expect(instance.get_node_or_null("WoodWallA/WoodenWallVisual/Model/world/geometry_0") is MeshInstance3D, "damageable walls use the imported wooden wall model")
	_expect(instance.get_node_or_null("WoodWallA/MeshInstance3D") == null, "wood wall primitive preview is removed")
	_expect(instance.get_node_or_null("CQBRoomLayout3D/NorthWestCrate/WoodenCrateVisual/Model/world/geometry_0") is MeshInstance3D, "rooms contain imported wooden crate cover")
	_expect(instance.get_node_or_null("CQBRoomLayout3D/NorthWestSandbags/SandbagVisual/Model/world/geometry_0") is MeshInstance3D, "rooms contain imported sandbag cover")
	var room_walls := _nodes_in_group_under(instance, &"cqb_room_walls")
	var room_covers := _nodes_in_group_under(instance, &"cqb_room_cover")
	var room_anchors := _nodes_in_group_under(instance, &"cqb_rooms")
	var door_anchors := _nodes_in_group_under(instance, &"cqb_doors")
	_expect(room_walls.size() >= 29, "room layout uses at least twenty-nine permanent wall segments")
	_expect(room_covers.size() >= 14, "rooms contain authored micro-cover instead of relying on open-floor screens")
	_expect(room_anchors.size() >= 12, "map exposes at least twelve local CQB room anchors")
	_expect(door_anchors.size() >= 10, "room connections expose at least ten staggered door anchors")
	for wall_node in room_walls:
		var room_wall := wall_node as StaticBody3D
		_expect(room_wall != null and room_wall.is_in_group("navigation_obstacles"), "room wall blocks navigation")
	for door_node in door_anchors:
		var door := door_node as Marker3D
		_expect(not navigation.is_world_position_blocked(door.global_position), "%s remains an open room connection" % door.name)
	for room_node in room_anchors:
		var room := room_node as Marker3D
		_expect(_count_nearby_axis_blocks(room, 8.5) >= 2, "%s has nearby structure on at least two axes" % room.name)
	_expect(instance.get_node_or_null("EnvironmentReactionHub") is GameEnvironmentReactionHub, "main scene contains environment reaction hub")
	var world_environment := instance.get_node_or_null("WorldEnvironment") as WorldEnvironment
	var sun := instance.get_node_or_null("Sun") as DirectionalLight3D
	_expect(world_environment != null and world_environment.environment != null, "main scene contains a configured world environment")
	if world_environment != null and world_environment.environment != null:
		_expect(world_environment.environment.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR, "environment uses its configured color as the ambient light source")
		_expect(world_environment.environment.ambient_light_energy >= 1.0 and world_environment.environment.ambient_light_energy <= 2.5, "ambient fill light stays readable without flattening scene contrast")
	_expect(sun != null and sun.light_energy >= 1.5, "map key light keeps actors and room geometry readable")
	var world_visibility := instance.get_node_or_null("WorldVisibility3D") as GameWorldVisibility3D
	_expect(world_visibility != null, "map retains visibility-aware enemy and environment event handling")
	_expect(instance.get_node_or_null("OilBarrelWall") is OilBarrelWall, "main scene contains oil barrel wall")
	_expect(instance.get_node_or_null("GasolineBarrelWall") is GasolineBarrelWall, "main scene contains gasoline barrel wall")
	_expect(instance.get_node_or_null("WoodWallA/HealthBar3D") is GameWorldHealthBar3D, "wood walls contain world health bars")
	_expect(instance.get_node_or_null("OilBarrelWall/HealthBar3D") is GameWorldHealthBar3D, "oil barrels contain world health bars")
	_expect(instance.get_node_or_null("GasolineBarrelWall/HealthBar3D") is GameWorldHealthBar3D, "gasoline barrels contain world health bars")
	_expect(instance.get_node_or_null("OilBarrelWall/OilDrumLeft/Model/world/geometry_0") is MeshInstance3D, "oil wall uses the imported oil drum model")
	_expect(instance.get_node_or_null("OilBarrelWall/BarrelLeft") == null, "oil barrel primitive preview is removed")
	_expect(instance.get_node_or_null("GasolineBarrelWall/FuelCanLeft/Model/world/geometry_0") is MeshInstance3D, "gasoline wall uses the imported fuel can model")
	_expect(instance.get_node_or_null("GasolineBarrelWall/BarrelLeft") == null, "gasoline barrel primitive preview is removed")
	_expect(instance.get_node_or_null("ContentSpawner3D/ObjectivePoint") is GameObjectivePoint3D, "main scene contains remote objective point")
	_expect(instance.get_node_or_null("ExtractionPoint") is GameExtractionPoint3D, "main scene contains spawn extraction point")
	_expect(instance.get_node_or_null("ContentSpawner3D/HealthPack1/VisualRoot/MedkitVisual/Model/world/geometry_0") is MeshInstance3D, "health pickup uses the imported medkit model")
	_expect(instance.get_node_or_null("ContentSpawner3D/ObjectivePoint/VisualRoot/MissionTerminalVisual/Model/world/geometry_0") is MeshInstance3D, "objective uses the imported mission terminal model")
	_expect(instance.get_node_or_null("ExtractionPoint/VisualRoot/ExtractionBeaconVisual/Model/world/geometry_0") is MeshInstance3D, "extraction uses the imported beacon model")
	_expect(instance.get_node_or_null("MissionController") is GameMissionController, "main scene contains mission controller")
	_expect(instance.get_node_or_null("HUD/ObjectiveIndicator") is GameObjectiveIndicator, "HUD contains edge objective indicator")
	_expect(instance.get_node_or_null("HUD/TouchControls") is GameTouchInputRouter, "main scene contains touch input router")
	_expect(instance.get_node_or_null("HUD/TouchControls/MoveJoystick") is GameVirtualJoystick, "touch layout contains movement joystick")
	_expect(instance.get_node_or_null("HUD/TouchControls/AimJoystick") is GameVirtualJoystick, "touch layout contains aim joystick")
	var fire_button := instance.get_node_or_null("HUD/TouchControls/FireButton") as GameFireAimButton
	_expect(fire_button != null, "touch layout contains dedicated fire button")
	_expect(fire_button != null and not fire_button.has_signal("aim_dragged"), "fire button no longer changes aim while pressed or dragged")
	_expect(player.get_node_or_null("LockIndicator") is Label3D, "player contains a world-space target lock indicator")
	var status_panel := instance.get_node_or_null("HUD/StatusPanel") as PanelContainer
	var result_panel := instance.get_node_or_null("HUD/ResultPanel") as PanelContainer
	var status_style := status_panel.get_theme_stylebox("panel") as StyleBoxFlat if status_panel != null else null
	var result_style := result_panel.get_theme_stylebox("panel") as StyleBoxFlat if result_panel != null else null
	_expect(status_style != null and status_style.bg_color.a <= 0.6, "gameplay status panel stays translucent so it does not hide the left sight line")
	_expect(result_style != null and result_style.bg_color.a >= 0.8, "result panel retains a more opaque summary background")
	if player != null and guard != null:
		_disable_all_guards(instance)
		var player_damage_feedback := player.get_node("DamageFeedback3D") as GameDamageFeedback3D
		var guard_damage_feedback := guard.get_node("DamageFeedback3D") as GameDamageFeedback3D
		_expect(player_damage_feedback.enable_haptics, "player damage feedback enables handheld haptics")
		_expect(player_damage_feedback.hit_haptic_duration_ms <= 40 and player_damage_feedback.hit_haptic_amplitude <= 0.35, "player hit haptic stays lightweight")
		_expect(not guard_damage_feedback.enable_haptics, "enemy damage feedback never vibrates the player's device")
		player.health.damaged.emit(1.0, guard)
		guard.health.damaged.emit(1.0, player)
		_expect(player_damage_feedback.hits_presented == 1, "player damage signal immediately triggers screen and model feedback")
		_expect(guard_damage_feedback.hits_presented == 1, "guard damage signal immediately triggers model feedback")
		var feedback := player.get_node("ShotFeedback3D") as GameShotFeedback3D
		_expect(is_zero_approx(feedback.recoil_distance), "shot feedback never moves the logical bullet origin away from the miniature muzzle")
		_expect(feedback.fire_haptic_duration_ms <= 20 and feedback.fire_haptic_amplitude <= 0.25, "successful fire uses a lightweight handheld haptic")
		var feedback_before := feedback.shots_presented
		var impact_endpoint := player.weapon.global_position + Vector3.FORWARD
		player.weapon.fired.emit(player.weapon.global_position, impact_endpoint, true)
		_expect(feedback.shots_presented == feedback_before + 1, "weapon fired signal immediately triggers presentation feedback")
		_expect(feedback.last_impact_position.distance_to(player.weapon.global_position) < impact_endpoint.distance_to(player.weapon.global_position), "wall impact marker offsets toward the shooter instead of hiding inside the surface")
		player.global_position = Vector3(0.0, 0.0, 5.0)
		player.set_aim_input(Vector2(0.0, -1.0), true)
		guard.global_position = Vector3.ZERO
		guard.rotation.y = PI
		await physics_frame
		_expect(player.vision.can_see(guard), "player vision sees guard inside 120 degree cone")
		_expect(guard.vision.can_see(player), "guard sees the player inside its shorter vision range")
		player.global_position = Vector3(0.0, 0.0, 9.0)
		await physics_frame
		_expect(player.vision.can_see(guard), "player sees a guard at 9 meters inside the 10 meter player vision")
		_expect(not guard.vision.can_see(player), "guard cannot see the player beyond its 8 meter vision")
		player.global_position = Vector3(0.0, 0.0, 5.0)
		await physics_frame

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

		_disable_all_guards(instance)
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
	var guard := instance.get_node("ContentSpawner3D/PistolGuard") as PistolGuard
	_disable_all_guards(instance)
	player.set_physics_process(false)
	var pickup_nodes := instance.get_tree().get_nodes_in_group("weapon_pickups")
	_expect(pickup_nodes.size() == 4, "main scene contains four special weapon pickups")
	for pickup_node in pickup_nodes:
		var pickup := pickup_node as GameWeaponPickup3D
		_expect(pickup != null and pickup.get_node_or_null("Visual/ImportedWeaponModel") != null, "weapon pickup uses its imported GLB model")
	_expect(instance.get_node_or_null("HUD/WeaponButtons/DefaultWeaponButton") is Button, "HUD contains default weapon switch button")
	_expect(instance.get_node_or_null("HUD/WeaponButtons/SpecialWeaponButton") is Button, "HUD contains special weapon switch button")
	_expect(instance.get_node_or_null("HUD/SwapWeaponButton") is Button, "HUD contains contextual weapon swap button")

	var heavy_pickup := instance.get_node("ContentSpawner3D/HeavyPistolPickup") as GameWeaponPickup3D
	_expect(heavy_pickup.collect_for_player(player), "empty special slot automatically collects weapon pickup")
	_expect(player.special_weapon != null and player.special_weapon.definition.weapon_id == &"heavy_pistol", "automatic pickup equips heavy pistol in special slot")
	_expect(player.pistol_miniature.visible and not player.rifle_miniature.visible and not player.rocket_miniature.visible, "heavy pistol keeps the pistol miniature visible")
	_expect(player.default_weapon != null and player.default_weapon.definition.weapon_id == &"standard_pistol", "special pickup permanently preserves standard pistol")
	player.special_weapon.set_ammo_state(4, 7)

	var machine_pickup := instance.get_node("ContentSpawner3D/MachineGunPickup") as GameWeaponPickup3D
	_expect(not machine_pickup.collect_for_player(player), "different special weapon requires explicit confirmation")
	_expect((instance.get_node("HUD/SwapWeaponButton") as Button).visible, "different pickup exposes temporary swap button")
	_expect(player.confirm_weapon_swap(), "player can confirm offered special weapon exchange")
	_expect(player.special_weapon.definition.weapon_id == &"machine_gun", "confirmed exchange equips new special weapon")
	_expect(player.to_local(player.special_weapon.global_position).is_equal_approx(player.special_weapon.definition.muzzle_position), "machine-gun ray starts at the visible rifle muzzle")
	_expect(player._weapon_visual_transition_active, "switching to the rifle miniature temporarily locks firing")
	_expect(not player.request_fire(), "player cannot fire while the weapon miniature is changing")
	await create_timer(0.35).timeout
	_expect(not player.pistol_miniature.visible and player.rifle_miniature.visible and not player.rocket_miniature.visible, "machine gun displays the complete rifle miniature")
	_expect(not player._weapon_visual_transition_active and not player.weapon_swap_pulse.visible, "rifle miniature transition finishes and clears its base pulse")
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
	var refill_pickup_scene := load("res://scenes/world/weapon_pickup_3d.tscn") as PackedScene
	var bonus_pickup := refill_pickup_scene.instantiate() as GameWeaponPickup3D
	bonus_pickup.definition = load("res://resources/weapons/machine_gun.tres") as WeaponDefinition
	instance.add_child(bonus_pickup)
	_expect(bonus_pickup.collect_for_player(player), "same-type pickup automatically replenishes reserve")
	_expect(player.special_weapon.reserve_ammo == 58, "same-type pickup adds its configured reserve ammunition")
	var full_pickup := refill_pickup_scene.instantiate() as GameWeaponPickup3D
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
	_expect(player._weapon_visual_transition_active, "automatic fallback uses the miniature transition")
	await create_timer(0.35).timeout
	_expect(player.pistol_miniature.visible and not player.rifle_miniature.visible and not player.rocket_miniature.visible, "returning to default weapon restores the pistol miniature")
	_expect(player.special_weapon != null and not player.special_weapon.has_any_ammo(), "exhausted special weapon remains stored in its slot")

	var rocket_definition := load("res://resources/weapons/rocket_launcher.tres") as WeaponDefinition
	player.equip_special_weapon(rocket_definition, 1, 0)
	_expect(player.to_local(player.special_weapon.global_position).is_equal_approx(rocket_definition.muzzle_position), "rocket projectile starts at the visible launcher muzzle")
	_expect(player._weapon_visual_transition_active, "switching to the rocket miniature temporarily locks firing")
	await create_timer(0.35).timeout
	_expect(not player.pistol_miniature.visible and not player.rifle_miniature.visible and player.rocket_miniature.visible, "rocket launcher displays the complete rocket miniature")
	player.global_position = Vector3(10.0, 0.0, 14.0)
	player.set_aim_input(Vector2(0.0, -1.0), true)
	player.call("_update_aim_direction", 0.016)
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
		_expect(spawned_rocket.get_node_or_null("ImportedRocketModel") != null, "rocket projectile uses the imported rocket GLB")
		_expect(is_equal_approx(spawned_rocket.maximum_distance_meters, 8.0), "rocket projectile inherits unified 8 meter CQB range")
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

func _test_aim_assist_and_blind_visibility() -> void:
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await physics_frame
	var debug_input := instance.get_node("DebugPlayerInput")
	debug_input.set_process(false)
	debug_input.set_process_unhandled_input(false)
	_disable_all_guards(instance)
	var player := instance.get_node("Player") as PlayerCharacter
	player.set_physics_process(false)
	player.global_position = Vector3(0.0, 0.0, 5.0)
	player.rotation = Vector3.ZERO
	var guards := _nodes_in_group_under(instance, &"guards")
	var primary := guards[0] as PistolGuard
	var secondary := guards[1] as PistolGuard
	for node in guards:
		(node as PistolGuard).global_position = Vector3(30.0, 0.0, 30.0)
	primary.global_position = Vector3(0.6, 0.0, 0.0)
	secondary.global_position = Vector3(1.2, 0.0, 0.0)
	var raw := Vector3(0.0, 0.0, -1.0)
	var assisted := player.aim_assist.resolve_direction(raw, true, 0.016)
	var primary_direction := primary.global_position - player.weapon.global_position
	primary_direction.y = 0.0
	primary_direction = primary_direction.normalized()
	_expect(player.aim_assist.locked_target == primary, "aim ray locks the guard closest to the selected direction")
	_expect(assisted.is_equal_approx(primary_direction), "target lock fully aligns aim with the selected guard")
	_expect((player.get_node("LockIndicator") as Label3D).visible, "acquiring a target immediately shows the lock indicator")
	var retained := player.aim_assist.resolve_direction(Vector3.RIGHT, false, 0.016)
	_expect(player.aim_assist.locked_target == primary and retained.is_equal_approx(primary_direction), "releasing aim input retains and follows the locked target")
	var secondary_direction := secondary.global_position - player.weapon.global_position
	secondary_direction.y = 0.0
	secondary_direction = secondary_direction.normalized()
	player.aim_assist.resolve_direction(secondary_direction, true, 0.016)
	_expect(player.aim_assist.locked_target == secondary, "sweeping the aim ray to another guard switches the lock")
	player.aim_assist.resolve_direction(Vector3.LEFT, true, 0.016)
	_expect(not player.aim_assist.has_lock(), "sweeping clearly into empty space releases the target lock")
	secondary.global_position = Vector3(30.0, 0.0, 30.0)
	player.aim_assist.resolve_direction(raw, true, 0.016)
	await physics_frame
	var ammo_before := player.weapon.ammo_in_magazine
	_expect(player.weapon.ammo_in_magazine == ammo_before, "acquiring a target never fires automatically")
	var primary_health_before := primary.health.current_health
	player.set_aim_input(Vector2(raw.x, raw.z), true)
	player.call("_update_aim_direction", 0.016)
	player.set_aim_input(Vector2.ZERO, false)
	player.call("_update_aim_direction", 0.016)
	_expect(player.aim_assist.locked_target == primary, "player retains the acquired lock after the right stick is released")
	_expect(bool(player.aim_line.get("_locked")), "retained target changes the persistent aim line to its locked state")
	_expect(player.request_fire(), "dedicated fire input shoots along the retained lock direction")
	_expect(primary.health.current_health < primary_health_before, "locked fire damages the selected guard without another aim input")
	var configured_range := player.weapon.definition.range_meters
	player.weapon.definition.range_meters = 4.0
	_expect(player.vision.can_see(primary), "guard beyond weapon range remains visible inside the vision cone")
	_expect(player.aim_assist.resolve_direction(raw, false, 0.016).is_equal_approx(raw), "target lock releases immediately when the guard leaves weapon range")
	_expect(not player.aim_assist.has_lock(), "out-of-range guard is no longer locked")
	player.weapon.definition.range_meters = configured_range

	primary.global_position = Vector3(0.0, 0.0, 10.0)
	_expect(player.aim_assist.resolve_direction(raw, true, 0.016).is_equal_approx(raw), "aim ray rejects a guard behind the player")
	player.global_position = Vector3(5.0, 0.0, -2.0)
	player.rotation = Vector3.ZERO
	primary.global_position = Vector3(5.0, 0.0, -5.0)
	player.aim_assist.resolve_direction(raw, true, 0.016)
	_expect(player.aim_assist.locked_target == primary, "aim ray can reacquire an unobstructed guard")
	primary.global_position = Vector3(5.0, 0.0, -9.0)
	player.aim_assist.resolve_direction(raw, false, 0.1)
	_expect(player.aim_assist.locked_target == primary and not (player.get_node("LockIndicator") as Label3D).visible, "brief wall occlusion retains the lock but hides its exact marker")
	player.aim_assist.resolve_direction(raw, false, 0.11)
	_expect(not player.aim_assist.has_lock(), "wall occlusion beyond the grace period releases the lock")
	primary.global_position = Vector3(5.0, 0.0, -5.0)
	player.aim_assist.resolve_direction(raw, true, 0.016)
	primary.current_state = PistolGuard.GuardState.DEAD
	player.aim_assist.resolve_direction(raw, false, 0.016)
	_expect(not player.aim_assist.has_lock(), "dead guard releases the target lock immediately")
	primary.current_state = PistolGuard.GuardState.PATROL
	player.global_position = Vector3(0.0, 0.0, 5.0)
	player.rotation = Vector3.ZERO

	var visibility := instance.get_node("WorldVisibility3D") as GameWorldVisibility3D
	var wall := instance.get_node("WoodWallD") as DamageableWall
	var wall_mesh := wall.find_child("geometry_0", true, false) as MeshInstance3D
	_expect(wall_mesh != null, "wood wall exposes its imported model mesh")
	player.rotation = Vector3(0.0, PI, 0.0)
	visibility.update_visibility_now()
	var map_material_before := wall_mesh.get_active_material(0) as StandardMaterial3D
	var map_color_before := map_material_before.albedo_color if map_material_before != null else Color.TRANSPARENT
	player.rotation = Vector3.ZERO
	visibility.update_visibility_now()
	var highlighted_material := wall_mesh.get_active_material(0) as StandardMaterial3D
	var highlighted_color := highlighted_material.albedo_color if highlighted_material != null else Color.TRANSPARENT
	_expect(wall.visible and highlighted_color.get_luminance() > map_color_before.get_luminance(), "building geometry becomes brighter inside the unobstructed player view")
	_expect(highlighted_material != null and not highlighted_material.emission_enabled, "visible building uses its corrected non-metallic material without a whitening emission layer")
	player.rotation = Vector3(0.0, PI, 0.0)
	visibility.update_visibility_now()
	var restored_material := wall_mesh.get_active_material(0) as StandardMaterial3D
	var restored_color := restored_material.albedo_color if restored_material != null else Color.TRANSPARENT
	_expect(restored_color.is_equal_approx(map_color_before), "building geometry returns to its stable base color outside the player view")

	primary.global_position = Vector3(3.0, 0.0, -1.0)
	primary.exposure_remaining = 0.0
	primary.call("_update_player_visibility")
	_expect(not primary.visual_root.visible, "blind dynamic guard remains hidden")
	var feedback_count := [0]
	visibility.blind_environment_event.connect(func(_kind: StringName, _direction: Vector2, _duration: float) -> void:
		feedback_count[0] += 1
	)
	_expect(visibility.report_environment_event(&"explosion", Vector3(5.0, 1.0, 5.0)), "blind explosion creates indirect feedback")
	_expect(feedback_count[0] == 1 and visibility.feedback_remaining > 0.0, "blind environment feedback is directional and time limited")
	_expect(not primary.visual_root.visible, "blind environment feedback does not reveal a guard")
	var oil := load("res://scenes/world/oil_barrel_wall.tscn").instantiate() as OilBarrelWall
	oil.position = Vector3(5.0, 0.0, 5.0)
	instance.add_child(oil)
	await physics_frame
	oil.apply_damage(oil.health.max_health, player)
	_expect(oil.is_burning and not oil.fire_indicator.visible, "blind fire hides its exact flame effect")
	_expect(feedback_count[0] == 2 and visibility.last_feedback_kind == &"fire", "blind fire emits only an indirect directional event")
	player.rotation = Vector3.ZERO
	oil.global_position = Vector3(0.0, 0.0, 0.0)
	visibility.update_visibility_now()
	_expect(oil.fire_indicator.visible, "fire restores its exact effect after entering effective vision")
	_expect(not visibility.report_environment_event(&"explosion", Vector3(0.0, 1.0, -1.0)), "visible explosion does not create a blind-area marker")
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
	var guard := instance.get_node("ContentSpawner3D/PistolGuard") as PistolGuard
	var objective := instance.get_node("ContentSpawner3D/ObjectivePoint") as GameObjectivePoint3D
	var extraction := instance.get_node("ExtractionPoint") as GameExtractionPoint3D
	var mission := instance.get_node("MissionController") as GameMissionController
	_disable_all_guards(instance)
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
	var initial_guard_count := mission.remaining_guards
	_expect(initial_guard_count >= 8 and initial_guard_count <= 12, "mission tracks randomized eight-to-twelve guard budget")
	_expect((instance.get_node("HUD/StatusPanel/Margin/Rows/EnemyCountLabel") as Label).text == "剩余警卫：%d" % initial_guard_count, "HUD displays randomized remaining enemy count as threat reference")

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
	var every_guard_alerted := true
	for node in instance.get_tree().get_nodes_in_group("guards"):
		if instance.is_ancestor_of(node) and (node as PistolGuard).current_state != PistolGuard.GuardState.INVESTIGATE:
			every_guard_alerted = false
	_expect(every_guard_alerted, "objective alarm alerts every surviving preplaced guard")
	var guard_alarm_target: Vector3 = guard.get("_last_known_player_position")
	_expect(guard_alarm_target.is_equal_approx(objective.global_position), "global alarm reveals only objective position to guard")
	player.global_position += Vector3(4.0, 0.0, 0.0)
	var retained_alarm_target: Vector3 = guard.get("_last_known_player_position")
	_expect(retained_alarm_target.is_equal_approx(objective.global_position), "objective alarm does not continuously reveal player position")

	player.global_position = extraction.global_position
	extraction.call("_on_body_entered", player)
	_expect(mission.current_phase == GameMissionController.MissionPhase.WON, "entering enabled spawn extraction wins immediately")
	_expect(mission.remaining_guards == initial_guard_count, "mission can be won without eliminating any remaining guards")
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
	var failure_guard := failure_instance.get_node("ContentSpawner3D/PistolGuard") as PistolGuard
	var failure_mission := failure_instance.get_node("MissionController") as GameMissionController
	_disable_all_guards(failure_instance)
	failure_player.set_physics_process(false)
	var failure_initial_guards := failure_mission.remaining_guards
	failure_guard.apply_damage(failure_guard.health.max_health, failure_player)
	_expect(failure_mission.remaining_guards == failure_initial_guards - 1 and failure_mission.kills == 1, "guard death immediately updates remaining count and kill statistic")
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
	var guard := instance.get_node("ContentSpawner3D/PistolGuard") as PistolGuard
	var sound_hub := instance.get_node("SoundEventHub") as GameSoundEventHub
	_disable_all_guards(instance)
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

func _test_audio_playback() -> void:
	var hub := GameSoundEventHub.new()
	hub.playback_pool_size = 4
	root.add_child(hub)
	await process_frame
	_expect(hub.get_child_count() == 4, "sound hub creates the configured 3D playback pool")
	for child in hub.get_children():
		_expect(child is AudioStreamPlayer3D, "sound hub playback voices are spatial audio players")
	var gunshot := hub.get_stream_for_cue(GameSoundEventHub.CUE_GUNSHOT)
	var rifle := hub.get_stream_for_cue(GameSoundEventHub.CUE_ASSAULT_RIFLE)
	var explosion := hub.get_stream_for_cue(GameSoundEventHub.CUE_EXPLOSION)
	_expect(gunshot != null and gunshot.resource_path.ends_with("gunshot.wav"), "pistol cue loads the gunshot audio resource")
	_expect(rifle != null and rifle.resource_path.ends_with("assault_rifle.wav"), "machine gun cue loads the assault rifle audio resource")
	_expect(explosion != null and explosion.resource_path.ends_with("explosion.wav"), "explosion cue loads the explosion audio resource")
	var first_footstep := hub.get_stream_for_cue(GameSoundEventHub.CUE_FOOTSTEP)
	hub.set("_footstep_sequence", 1)
	var second_footstep := hub.get_stream_for_cue(GameSoundEventHub.CUE_FOOTSTEP)
	_expect(first_footstep != null and second_footstep != null and first_footstep != second_footstep, "footstep events alternate concrete and road recordings")
	_expect(hub.playback_pool_size > 1, "sound hub reserves multiple voices for overlapping spatial events")
	hub.queue_free()
	await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _disable_all_guards(instance: Node) -> void:
	for node in instance.get_tree().get_nodes_in_group("guards"):
		if node is PistolGuard and instance.is_ancestor_of(node):
			(node as PistolGuard).set_physics_process(false)

func _nodes_in_group_under(instance: Node, group_name: StringName) -> Array[Node]:
	var result: Array[Node] = []
	for node in instance.get_tree().get_nodes_in_group(group_name):
		if instance.is_ancestor_of(node):
			result.append(node)
	return result

func _position_is_candidate(node: Node3D, container: Node) -> bool:
	for candidate in container.get_children():
		if candidate is Node3D and node.global_position.is_equal_approx((candidate as Node3D).global_position):
			return true
	return false

func _count_nearby_axis_blocks(anchor: Node3D, maximum_distance: float) -> int:
	var origin := anchor.global_position + Vector3.UP
	var count := 0
	for direction in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * maximum_distance, 2)
		if not anchor.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			count += 1
	return count
