extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_weapon_definition()
	_test_health_component()
	await _test_main_scene()
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

func _test_main_scene() -> void:
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	_expect(scene != null, "main scene loads")
	if scene == null:
		return
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await physics_frame
	var player := instance.get_node_or_null("Player") as PlayerCharacter
	_expect(player != null, "main scene contains player")
	_expect(instance.get_node_or_null("Camera3D") is FixedFollowCamera, "main scene contains fixed camera")
	_expect(instance.get_tree().get_nodes_in_group("damageable_walls").size() == 4, "main scene contains four damageable wall modules")
	_expect(instance.get_node_or_null("HUD/TouchControls") is GameTouchInputRouter, "main scene contains touch input router")
	_expect(instance.get_node_or_null("HUD/TouchControls/MoveJoystick") is GameVirtualJoystick, "touch layout contains movement joystick")
	_expect(instance.get_node_or_null("HUD/TouchControls/AimJoystick") is GameVirtualJoystick, "touch layout contains aim joystick")
	_expect(instance.get_node_or_null("HUD/TouchControls/FireButton") is GameFireAimButton, "touch layout contains draggable fire button")
	if player != null:
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

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
