class_name GameExtractionPoint3D
extends Area3D

signal enabled_changed(enabled: bool)
signal extracted(player: PlayerCharacter)

var extraction_enabled := false
var _has_extracted := false

@onready var _zone: MeshInstance3D = $VisualRoot/Zone
@onready var _label: Label3D = $VisualRoot/Label3D

func _ready() -> void:
	add_to_group("extraction_points")
	body_entered.connect(_on_body_entered)
	_apply_visual_state()

func set_extraction_enabled(value: bool) -> void:
	if extraction_enabled == value or _has_extracted:
		return
	extraction_enabled = value
	_apply_visual_state()
	enabled_changed.emit(extraction_enabled)

func _on_body_entered(body: Node3D) -> void:
	if extraction_enabled and body is PlayerCharacter:
		_extract(body as PlayerCharacter)

func _extract(player: PlayerCharacter) -> void:
	if _has_extracted:
		return
	_has_extracted = true
	extracted.emit(player)

func _apply_visual_state() -> void:
	if _zone == null or _label == null:
		return
	var color := Color(0.2, 1.0, 0.52, 0.66) if extraction_enabled else Color(0.35, 0.4, 0.46, 0.32)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.emission_enabled = extraction_enabled
	material.emission = color
	material.emission_energy_multiplier = 1.7
	_zone.material_override = material
	_label.text = "撤离点 · 立即撤离" if extraction_enabled else "出生点"
