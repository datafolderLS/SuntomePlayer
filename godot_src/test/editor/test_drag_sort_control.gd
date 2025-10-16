extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var ctrl = preload("res://editor/base/param_ctrl.tscn")
	var arry : Array = Array()
	for i in range(4):
		arry.push_back(SpinBox.new())

	%DragSortControl.set_array(arry)

	%Button.pressed.connect(
		func() :
			var list = %DragSortControl.get_array()
			for i in list:
				print(i.value)
	)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
