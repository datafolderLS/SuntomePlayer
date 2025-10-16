class_name NodeParamCtrl extends HBoxContainer

#用户修改百分率后激活该信号
signal value_change(node : NodeParamCtrl)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not %SpinBox.value_changed.is_connected(_v_change):
		%SpinBox.value_changed.connect(_v_change)

	%mb_selection.about_to_popup.connect(func():
		#遍历所有的suntome_node，将所有的选项集合
		var keys := Dictionary()
		for node in SuntomeGlobal.suntome_nodes.values():
			if node is SuntomeParaNode:
				for key in node.change_operation.keys():
					keys.set(key, 0)

		#基于集合构建mb_selection的下拉菜单
		var popup : PopupMenu = %mb_selection.get_popup()
		_clear_popupitem()
		for key in keys.keys():
			popup.add_item(key)
		pass
	)

	%mb_selection.get_popup().index_pressed.connect(
		func(bindex : int):
			if 0 == bindex:
				%TabContainer.current_tab = 0
			else:
				%TabContainer.current_tab = 1
				%para_name.text = %mb_selection.get_popup().get_item_text(bindex)
			value_change.emit(self)
			pass
	)
	pass # Replace with function body.

func set_index(in_index : int):
	%Label.text = String.num_int64(in_index)


func index() -> int:
	return int(%Label.text)


func set_value(in_value):
	if typeof(in_value) == TYPE_STRING:
		%TabContainer.current_tab = 1
		%para_name.text = in_value
	elif typeof(in_value) == TYPE_FLOAT or typeof(in_value) == TYPE_INT:
		%TabContainer.current_tab = 0
		%SpinBox.set_value_no_signal(100.0 * in_value)
	else:
		printerr("TYPE NOT CORRECT")
		print_debug("ERROR")


func value():
	if 0 == %TabContainer.current_tab:
		return %SpinBox.value / 100.0
	else:
		return %para_name.text


func _v_change(_v : float):
	value_change.emit(self)
	pass


#清空下拉菜单，除了第一个默认选项
func _clear_popupitem():
	var popup : PopupMenu = %mb_selection.get_popup()
	var count = popup.item_count
	for i in range(count-1):
		popup.remove_item(1)
