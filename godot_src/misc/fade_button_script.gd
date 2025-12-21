class_name FadeButtonScript extends Control

signal pressed()

@export var mouse_mask : MouseButton = MOUSE_BUTTON_LEFT


func _ready():
	mouse_entered.connect(func():
		for cc in get_children():
			cc.visible = true
	)

	mouse_exited.connect(func():
		for cc in get_children():
			cc.visible = false
	)

	for cc in get_children():
		cc.visible = false
	pass


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if mouse_mask == event.button_index and event.pressed:
			pressed.emit()
