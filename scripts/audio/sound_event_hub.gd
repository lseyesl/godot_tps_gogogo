class_name GameSoundEventHub
extends Node3D

signal sound_emitted(position: Vector3, radius: float, priority: int, source: Node)

const CUE_FOOTSTEP: StringName = &"footstep"
const CUE_GUNSHOT: StringName = &"gunshot"
const CUE_ASSAULT_RIFLE: StringName = &"assault_rifle"
const CUE_ROCKET_LAUNCH: StringName = &"rocket_launch"
const CUE_EXPLOSION: StringName = &"explosion"

const GUNSHOT_STREAM: AudioStream = preload("res://assets/audio/prototypes/gunshot.wav")
const ASSAULT_RIFLE_STREAM: AudioStream = preload("res://assets/audio/prototypes/assault_rifle.wav")
const EXPLOSION_STREAM: AudioStream = preload("res://assets/audio/prototypes/explosion.wav")
const FOOTSTEP_CONCRETE_STREAM: AudioStream = preload("res://assets/audio/prototypes/footsteps_concrete.mp3")
const FOOTSTEP_ROAD_STREAM: AudioStream = preload("res://assets/audio/prototypes/footsteps_road.wav")

enum Priority {
	FOOTSTEP = 1,
	ENVIRONMENT = 2,
	GUNSHOT = 3,
	EXPLOSION = 4,
	ALARM = 5,
}

@export_range(1, 32, 1) var playback_pool_size: int = 16
@export var playback_max_distance_meters: float = 48.0
@export var playback_unit_size_meters: float = 5.0

var _players: Array[AudioStreamPlayer3D] = []
var _playback_remaining: Dictionary = {}
var _footstep_sequence: int = 0

func _ready() -> void:
	add_to_group("sound_event_hub")
	_build_playback_pool()

func _process(delta: float) -> void:
	for player in _players:
		var player_id := player.get_instance_id()
		if not _playback_remaining.has(player_id):
			continue
		var remaining: float = maxf(0.0, float(_playback_remaining[player_id]) - delta)
		if is_zero_approx(remaining):
			player.stop()
			_playback_remaining.erase(player_id)
		else:
			_playback_remaining[player_id] = remaining

func _exit_tree() -> void:
	for player in _players:
		player.stop()
		player.stream = null
	_playback_remaining.clear()

func emit_sound_event(
	position: Vector3,
	radius: float,
	priority: int,
	source: Node = null,
	cue: StringName = &""
) -> void:
	if radius <= 0.0:
		return
	sound_emitted.emit(position, radius, priority, source)
	_play_audio_event(position, priority, cue)

func get_stream_for_cue(cue: StringName) -> AudioStream:
	match cue:
		CUE_FOOTSTEP:
			return FOOTSTEP_CONCRETE_STREAM if _footstep_sequence % 2 == 0 else FOOTSTEP_ROAD_STREAM
		CUE_ASSAULT_RIFLE:
			return ASSAULT_RIFLE_STREAM
		CUE_EXPLOSION:
			return EXPLOSION_STREAM
		CUE_GUNSHOT, CUE_ROCKET_LAUNCH:
			return GUNSHOT_STREAM
	return null

func get_active_player_count() -> int:
	var active := 0
	for player in _players:
		if player.playing:
			active += 1
	return active

func _build_playback_pool() -> void:
	if not _players.is_empty():
		return
	for index in playback_pool_size:
		var player := AudioStreamPlayer3D.new()
		player.name = "AudioVoice%02d" % index
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		player.unit_size = playback_unit_size_meters
		player.max_distance = playback_max_distance_meters
		player.panning_strength = 1.5
		add_child(player)
		_players.append(player)

func _play_audio_event(position: Vector3, priority: int, requested_cue: StringName) -> void:
	if _players.is_empty():
		return
	var cue := requested_cue if not requested_cue.is_empty() else _default_cue_for_priority(priority)
	var stream := get_stream_for_cue(cue)
	if stream == null:
		return
	var player := _claim_player()
	if player == null:
		return
	var settings := _playback_settings(cue)
	player.global_position = position
	player.stream = stream
	player.volume_db = settings.volume_db
	player.pitch_scale = settings.pitch_scale
	player.play(settings.start_offset)
	var duration: float = settings.duration
	if duration > 0.0:
		_playback_remaining[player.get_instance_id()] = duration
	if cue == CUE_FOOTSTEP:
		_footstep_sequence += 1

func _claim_player() -> AudioStreamPlayer3D:
	for player in _players:
		if not player.playing:
			_playback_remaining.erase(player.get_instance_id())
			return player
	var oldest: AudioStreamPlayer3D = _players.pop_front()
	_players.append(oldest)
	oldest.stop()
	_playback_remaining.erase(oldest.get_instance_id())
	return oldest

func _default_cue_for_priority(priority: int) -> StringName:
	match priority:
		Priority.FOOTSTEP:
			return CUE_FOOTSTEP
		Priority.GUNSHOT:
			return CUE_GUNSHOT
		Priority.EXPLOSION:
			return CUE_EXPLOSION
	return &""

func _playback_settings(cue: StringName) -> Dictionary:
	match cue:
		CUE_FOOTSTEP:
			return {
				"start_offset": 0.0,
				"duration": 0.24,
				"volume_db": -8.0,
				"pitch_scale": 1.0 + float((_footstep_sequence % 3) - 1) * 0.035,
			}
		CUE_ASSAULT_RIFLE:
			return {"start_offset": 0.0, "duration": 0.18, "volume_db": -4.0, "pitch_scale": 1.0}
		CUE_ROCKET_LAUNCH:
			return {"start_offset": 0.0, "duration": 0.8, "volume_db": -2.0, "pitch_scale": 0.72}
		CUE_EXPLOSION:
			return {"start_offset": 0.0, "duration": 4.5, "volume_db": -1.0, "pitch_scale": 1.0}
	return {"start_offset": 0.0, "duration": 1.2, "volume_db": -3.0, "pitch_scale": 1.0}

static func find_in_tree(node: Node) -> GameSoundEventHub:
	if node == null or node.get_tree() == null:
		return null
	return node.get_tree().get_first_node_in_group("sound_event_hub") as GameSoundEventHub
