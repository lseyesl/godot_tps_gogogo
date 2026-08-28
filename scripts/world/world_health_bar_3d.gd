class_name GameWorldHealthBar3D
extends Node3D

@export var health_path: NodePath
@export_range(0.1, 3.0, 0.05) var display_seconds := 1.8
@export_range(0.2, 2.0, 0.05) var width_meters := 0.9
@export_range(0.03, 0.4, 0.01) var height_meters := 0.1

var presentations := 0
var fill_ratio := 1.0
var _remaining := 0.0
var _health: HealthComponent
var _fill_mesh: QuadMesh
var _fill_material: StandardMaterial3D

func _ready() -> void:
	_health = get_node(health_path) as HealthComponent
	_create_visuals()
	_health.health_changed.connect(_on_health_changed)
	_health.damaged.connect(_on_damaged)
	_health.depleted.connect(_on_depleted)
	_update_fill(_health.current_health, _health.max_health)
	visible = false
	set_process(false)

func _process(delta: float) -> void:
	_remaining = maxf(0.0, _remaining - delta)
	if is_zero_approx(_remaining):
		visible = false
		set_process(false)

func _on_health_changed(current: float, maximum: float) -> void:
	_update_fill(current, maximum)

func _on_damaged(_amount: float, _source: Node) -> void:
	presentations += 1
	_remaining = display_seconds
	visible = _health.current_health > 0.0
	set_process(visible)

func _on_depleted(_source: Node) -> void:
	visible = false
	set_process(false)

func _create_visuals() -> void:
	var background := MeshInstance3D.new()
	var background_mesh := QuadMesh.new()
	background_mesh.size = Vector2(width_meters, height_meters)
	background.mesh = background_mesh
	background.material_override = _make_material(Color(0.025, 0.03, 0.035, 0.9))
	background.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	background.add_to_group(&"visibility_overlay_exempt")
	add_child(background)

	var fill := MeshInstance3D.new()
	_fill_mesh = QuadMesh.new()
	_fill_mesh.size = Vector2(width_meters, height_meters * 0.62)
	_fill_mesh.center_offset = Vector3(0.0, 0.0, 0.006)
	fill.mesh = _fill_mesh
	_fill_material = _make_material(Color(0.25, 0.95, 0.36, 0.98))
	fill.material_override = _fill_material
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fill.add_to_group(&"visibility_overlay_exempt")
	add_child(fill)

func _update_fill(current: float, maximum: float) -> void:
	fill_ratio = clampf(current / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0
	var filled_width := maxf(0.001, width_meters * fill_ratio)
	_fill_mesh.size = Vector2(filled_width, height_meters * 0.62)
	_fill_mesh.center_offset = Vector3(-(width_meters - filled_width) * 0.5, 0.0, 0.006)
	var color := Color(0.25, 0.95, 0.36, 0.98)
	if fill_ratio <= 0.3:
		color = Color(1.0, 0.18, 0.08, 0.98)
	elif fill_ratio <= 0.6:
		color = Color(1.0, 0.72, 0.12, 0.98)
	_fill_material.albedo_color = color
	_fill_material.emission = color

func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.render_priority = 1
	return material
