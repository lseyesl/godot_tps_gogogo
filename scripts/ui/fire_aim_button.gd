class_name GameFireAimButton
extends Control

signal fire_pressed
signal fire_released

@export_range(20.0, 120.0, 1.0) var button_radius: float = 48.0
@export var idle_color := Color(0.78, 0.24, 0.18, 0.58)
@export var pressed_color := Color(1.0, 0.36, 0.22, 0.9)

var _touch_index := -1
var _mouse_pressed := false

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
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_pressed = event.pressed
		if _mouse_pressed:
			_begin_press(event.position)
		else:
			_end_press()
		accept_event()
	elif event is InputEventMouseMotion and _mouse_pressed:
		accept_event()

func _draw() -> void:
	var center := size * 0.5
	var color := pressed_color if _is_pressed() else idle_color
	draw_circle(center, button_radius, color)
	draw_arc(center, button_radius * 0.56, 0.0, TAU, 32, Color.WHITE, 3.0, true)
	draw_line(center + Vector2(-18, 0), center + Vector2(18, 0), Color.WHITE, 2.0, true)
	draw_line(center + Vector2(0, -18), center + Vector2(0, 18), Color.WHITE, 2.0, true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _begin_press(_local_position: Vector2) -> void:
	fire_pressed.emit()
	queue_redraw()

func _end_press() -> void:
	fire_released.emit()
	queue_redraw()

func _is_pressed() -> bool:
	return _touch_index != -1 or _mouse_pressed
