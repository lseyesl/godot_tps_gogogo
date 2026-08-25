class_name FixedFollowCamera
extends Camera3D

@export var target_path: NodePath
@export var offset := Vector3(0.0, 18.0, 14.0)
@export var look_at_height: float = 0.8
@export_range(0.1, 30.0, 0.1) var follow_sharpness: float = 12.0

@onready var _target: Node3D = get_node(target_path) as Node3D

func _ready() -> void:
	if _target != null:
		global_position = _target.global_position + offset
		look_at(_target.global_position + Vector3.UP * look_at_height, Vector3.UP)

func _process(delta: float) -> void:
	if _target == null:
		return
	var desired := _target.global_position + offset
	global_position = global_position.lerp(desired, 1.0 - exp(-follow_sharpness * delta))
	look_at(_target.global_position + Vector3.UP * look_at_height, Vector3.UP)
