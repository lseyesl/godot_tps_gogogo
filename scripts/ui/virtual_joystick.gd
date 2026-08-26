class_name GameVirtualJoystick
extends Control

signal vector_changed(value: Vector2)

@export_range(20.0, 160.0, 1.0) var movement_radius: float = 58.0
@export_range(0.0, 0.4, 0.01) var deadzone: float = 0.12
@export var base_color := Color(0.2, 0.28, 0.36, 0.48)
@export var knob_color := Color(0.42, 0.95, 0.8, 0.82)

var value := Vector2.ZERO
var _touch_index := -1
var _mouse_dragging := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2.ONE * movement_radius * 2.4
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_update_value(event.position)
			accept_event()
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_reset()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_value(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_dragging = event.pressed
		if _mouse_dragging:
			_update_value(event.position)
		else:
			_reset()
		accept_event()
	elif event is InputEventMouseMotion and _mouse_dragging:
		_update_value(event.position)
		accept_event()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, movement_radius, base_color)
	draw_arc(center, movement_radius, 0.0, TAU, 48, base_color.lightened(0.22), 3.0, true)
	draw_circle(center + value * movement_radius, movement_radius * 0.42, knob_color)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _update_value(local_position: Vector2) -> void:
	var delta := local_position - size * 0.5
	var raw := (delta / movement_radius).limit_length(1.0)
	var strength := raw.length()
	if strength <= deadzone:
		value = Vector2.ZERO
	else:
		var normalized_strength := clampf((strength - deadzone) / (1.0 - deadzone), 0.0, 1.0)
		value = raw.normalized() * sqrt(normalized_strength)
	vector_changed.emit(value)
	queue_redraw()

func _reset() -> void:
	value = Vector2.ZERO
	vector_changed.emit(value)
	queue_redraw()
