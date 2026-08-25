class_name GameFireAimButton
extends Control

signal fire_pressed
signal fire_released
signal aim_dragged(value: Vector2)

@export_range(20.0, 120.0, 1.0) var button_radius: float = 48.0
@export_range(20.0, 180.0, 1.0) var drag_radius: float = 90.0
@export var idle_color := Color(0.78, 0.24, 0.18, 0.58)
@export var pressed_color := Color(1.0, 0.36, 0.22, 0.9)

var _touch_index := -1
var _mouse_pressed := false
var _press_origin := Vector2.ZERO
var _drag_value := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2.ONE * button_radius * 2.4
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_begin_press(event.position)
			accept_event()
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_end_press()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_drag(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_pressed = event.pressed
		if _mouse_pressed:
			_begin_press(event.position)
		else:
			_end_press()
		accept_event()
	elif event is InputEventMouseMotion and _mouse_pressed:
		_update_drag(event.position)
		accept_event()

func _draw() -> void:
	var center := size * 0.5
	var color := pressed_color if _is_pressed() else idle_color
	draw_circle(center, button_radius, color)
	draw_arc(center, button_radius * 0.56, 0.0, TAU, 32, Color.WHITE, 3.0, true)
	draw_line(center + Vector2(-18, 0), center + Vector2(18, 0), Color.WHITE, 2.0, true)
	draw_line(center + Vector2(0, -18), center + Vector2(0, 18), Color.WHITE, 2.0, true)
	if _drag_value.length_squared() > 0.01:
		draw_line(center, center + _drag_value * button_radius, Color.WHITE, 4.0, true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _begin_press(local_position: Vector2) -> void:
	_press_origin = local_position
	_drag_value = Vector2.ZERO
	fire_pressed.emit()
	queue_redraw()

func _update_drag(local_position: Vector2) -> void:
	_drag_value = ((local_position - _press_origin) / drag_radius).limit_length(1.0)
	if _drag_value.length_squared() > 0.01:
		aim_dragged.emit(_drag_value)
	queue_redraw()

func _end_press() -> void:
	_drag_value = Vector2.ZERO
	fire_released.emit()
	queue_redraw()

func _is_pressed() -> bool:
	return _touch_index != -1 or _mouse_pressed
