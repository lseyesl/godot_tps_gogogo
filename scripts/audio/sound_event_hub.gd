class_name GameSoundEventHub
extends Node

signal sound_emitted(position: Vector3, radius: float, priority: int, source: Node)

enum Priority {
	FOOTSTEP = 1,
	ENVIRONMENT = 2,
	GUNSHOT = 3,
	EXPLOSION = 4,
	ALARM = 5,
}

func _ready() -> void:
	add_to_group("sound_event_hub")

func emit_sound_event(
	position: Vector3,
	radius: float,
	priority: int,
	source: Node = null
) -> void:
	if radius <= 0.0:
		return
	sound_emitted.emit(position, radius, priority, source)

static func find_in_tree(node: Node) -> GameSoundEventHub:
	if node == null or node.get_tree() == null:
		return null
	return node.get_tree().get_first_node_in_group("sound_event_hub") as GameSoundEventHub
