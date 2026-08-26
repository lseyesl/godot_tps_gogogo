class_name GameMiniatureVisual3D
extends Node3D

@export var faction_color := Color(0.18, 0.78, 0.68, 1.0)

func _ready() -> void:
	apply_faction_color(faction_color)

func apply_faction_color(color: Color) -> void:
	faction_color = color
	for child in find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var tinted := StandardMaterial3D.new()
		tinted.albedo_color = color
		tinted.metallic = 0.08
		tinted.roughness = 0.72
		mesh_instance.material_override = tinted
