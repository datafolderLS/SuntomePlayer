class_name DragAbleItem extends HBoxContainer


signal index_changed(item : DragAbleItem)


var _do_drag : bool = false
var _do_drag_pre_index : int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%button.gui_input.connect(_button_gui_input)
	%button.button_down.connect(
		func():
			_do_drag = true
			_do_drag_pre_index = get_index()
	)
	%button.button_up.connect(
		func():
			_do_drag = false
			if get_index() != _do_drag_pre_index:
				#index变化，触发信号
				index_changed.emit(self)

	)
	pass # Replace with function body.


func container() -> MarginContainer:
	return get_node("MarginContainer")


func _parent_container() -> VBoxContainer:
	return get_parent()


func content() -> Control:
	return container().get_child(0)


func remove_content_and_return() -> Control:
	var rel = container().get_child(0)
	container().remove_child(rel)
	return rel


func _button_gui_input(input : InputEvent):
	if input is InputEventMouseMotion and _do_drag:
		#print("drag start ", input.position)
		if input.position.y < -10:
			var newIndex = get_index() - 1
			if newIndex < 0:
				newIndex = 0

			_parent_container().move_child(self, newIndex)
		elif input.position.y > size.y + 10:
			var newIndex = get_index() + 1
			var max_num = _parent_container().get_child_count() - 1
			if newIndex > max_num:
				newIndex = max_num
			_parent_container().move_child(self, newIndex)
	pass


#拖拽实现
#func _get_drag_data(at_position: Vector2) -> Variant:
	#if not Rect2(Vector2(0,0), %Label.size()).has_point(%Label.get_local_mouse_position()):
		#return null
#
	#var text := itemlist.get_item_text(index)
	#var label = Label.new()
	#label.text = text
#
	#set_drag_preview(label)
	#return text
	#pass
