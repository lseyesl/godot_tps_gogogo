class_name GameMiniatureVisual3D
extends Node3D

const FACTION_TINT_SHADER := preload("res://shaders/miniature_faction_tint.gdshader")

@export var faction_color := Color(0.08, 0.48, 0.46, 1.0)

func _ready() -> void:
	apply_faction_color(faction_color)

func apply_faction_color(color: Color) -> void:
	faction_color = color
	for child in find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var tinted := ShaderMaterial.new()
		tinted.shader = FACTION_TINT_SHADER
		tinted.set_shader_parameter("faction_color", color)
		var source_material := mesh_instance.mesh.surface_get_material(0) as BaseMaterial3D
		if source_material != null and source_material.albedo_texture != null:
			tinted.set_shader_parameter("albedo_texture", source_material.albedo_texture)
			tinted.set_shader_parameter("has_albedo_texture", true)
		mesh_instance.material_override = tinted
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
