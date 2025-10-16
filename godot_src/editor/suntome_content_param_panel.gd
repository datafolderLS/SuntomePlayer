extends VBoxContainer

var order_changed_cb : Callable
var ob_item_selected_cb : Callable
var button_normalization_cb : Callable
var cb_pressed_change_cb : Callable


func _ready() -> void:
	for key in Utility.RandomHelper.Method.keys():
		%OB_type.add_item(key, Utility.RandomHelper.Method[key])

	%OB_type.item_selected.connect(
		func(id : int):
			if ob_item_selected_cb.is_valid():
				ob_item_selected_cb.call(id)
			pass
	)

	%ButtonNormalization.pressed.connect(
		func():
			if button_normalization_cb.is_valid():
				button_normalization_cb.call()
	)

	%DragSortControl.order_changed.connect(
		func():
			if order_changed_cb.is_valid():
				order_changed_cb.call()
	)

	%CB_isSuntome.toggled.connect(
		func(value : bool):
			if cb_pressed_change_cb.is_valid():
				cb_pressed_change_cb.call(value)
	)
