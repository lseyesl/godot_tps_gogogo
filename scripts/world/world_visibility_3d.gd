class_name GameWorldVisibility3D
extends Node

signal blind_environment_event(kind: StringName, direction: Vector2, duration: float)

@export var player_path: NodePath
@export_range(0.02, 1.0, 0.01) var update_interval_seconds: float = 0.1
@export_range(0.0, 1.0, 0.01) var blind_brightness: float = 0.3
@export_range(0.0, 1.0, 0.01) var blind_saturation: float = 0.18
@export_range(0.1, 3.0, 0.1) var feedback_duration_seconds: float = 1.0
@export_range(0.0, 2.0, 0.05) var static_surface_tolerance: float = 0.65

var last_feedback_kind: StringName
var last_feedback_direction := Vector2.ZERO
var feedback_remaining := 0.0
var _update_remaining := 0.0
var _material_states: Dictionary = {}

@onready var player: PlayerCharacter = get_node(player_path) as PlayerCharacter

func _ready() -> void:
	add_to_group("world_visibility")
	var reaction_hub := GameEnvironmentReactionHub.find_in_tree(self)
	if reaction_hub != null:
		reaction_hub.explosion_resolved.connect(_on_explosion_resolved)
		reaction_hub.fire_propagated.connect(_on_fire_propagated)
	update_visibility_now()

func _process(delta: float) -> void:
	feedback_remaining = maxf(0.0, feedback_remaining - delta)
	_update_remaining = maxf(0.0, _update_remaining - delta)
	if is_zero_approx(_update_remaining):
		update_visibility_now()
		_update_remaining = update_interval_seconds

func update_visibility_now() -> void:
	if player == null or player.vision == null:
		return
	for node in get_tree().get_nodes_in_group(&"static_visibility"):
		if node is Node3D:
			_apply_static_visibility(node as Node3D, is_static_position_visible((node as Node3D).global_position))
	for node in get_tree().get_nodes_in_group(&"active_fire"):
		if node is Node3D:
			_set_fire_effect_visible(node as Node3D, is_static_position_visible((node as Node3D).global_position))

func is_static_position_visible(position: Vector3) -> bool:
	if player == null or player.vision == null or not player.vision.is_position_in_view(position):
		return false
	var eye := player.vision.get_eye_position()
	var delta := position - eye
	delta.y = 0.0
	var distance := delta.length()
	if distance <= 0.001:
		return true
	return distance <= player.vision.get_occluded_distance(delta / distance) + static_surface_tolerance

func report_environment_event(kind: StringName, position: Vector3) -> bool:
	if player == null or player.vision == null or player.vision.is_position_in_view(position) and player.vision.has_clear_line_to_position(position):
		return false
	var delta := position - player.global_position
	delta.y = 0.0
	if delta.length_squared() <= 0.001:
		return false
	last_feedback_kind = kind
	last_feedback_direction = Vector2(delta.x, delta.z).normalized()
	feedback_remaining = feedback_duration_seconds
	blind_environment_event.emit(kind, last_feedback_direction, feedback_duration_seconds)
	return true

func _apply_static_visibility(root_node: Node3D, in_view: bool) -> void:
	var meshes: Array[MeshInstance3D] = []
	if root_node is MeshInstance3D:
		meshes.append(root_node as MeshInstance3D)
	for child in root_node.find_children("*", "MeshInstance3D", true, false):
		meshes.append(child as MeshInstance3D)
	for mesh_instance in meshes:
		if mesh_instance == null or _is_environment_effect(mesh_instance):
			continue
		var key := mesh_instance.get_instance_id()
		if not _material_states.has(key):
			var original := mesh_instance.material_override as StandardMaterial3D
			if original == null and mesh_instance.mesh != null and mesh_instance.mesh.get_surface_count() > 0:
				original = mesh_instance.mesh.surface_get_material(0) as StandardMaterial3D
			if original == null:
				continue
			var visible_material := original.duplicate() as StandardMaterial3D
			var blind_material := original.duplicate() as StandardMaterial3D
			blind_material.albedo_color = _desaturate(original.albedo_color) * blind_brightness
			blind_material.albedo_color.a = original.albedo_color.a
			if blind_material.emission_enabled:
				blind_material.emission *= blind_brightness
			_material_states[key] = {"visible": visible_material, "blind": blind_material}
		var state: Dictionary = _material_states[key]
		mesh_instance.material_override = state.visible if in_view else state.blind

func _desaturate(color: Color) -> Color:
	var luminance := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
	return Color(
		lerpf(luminance, color.r, blind_saturation),
		lerpf(luminance, color.g, blind_saturation),
		lerpf(luminance, color.b, blind_saturation),
		color.a
	)

func _is_environment_effect(mesh_instance: MeshInstance3D) -> bool:
	var parent := mesh_instance.get_parent()
	return parent != null and parent.name == &"FireIndicator"

func _set_fire_effect_visible(source: Node3D, in_view: bool) -> void:
	var indicator := source.get_node_or_null("FireIndicator") as Node3D
	if indicator != null:
		indicator.visible = in_view

func _on_explosion_resolved(position: Vector3, _radius: float, _source: Node) -> void:
	report_environment_event(&"explosion", position)

func _on_fire_propagated(source: Node3D) -> void:
	if source == null or not is_instance_valid(source):
		return
	var in_view := player != null and player.vision != null and is_static_position_visible(source.global_position)
	_set_fire_effect_visible(source, in_view)
	if not in_view:
		report_environment_event(&"fire", source.global_position)
