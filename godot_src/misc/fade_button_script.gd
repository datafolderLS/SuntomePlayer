class_name FadeButtonScript extends Control

signal pressed()


@export var mouse_mask : MouseButton = MOUSE_BUTTON_LEFT

func _process(_delta: float) -> void:
	if Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position()):
		visible = true
	else :
		visible = false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if mouse_mask == event.button_index and event.pressed:
			pressed.emit()
