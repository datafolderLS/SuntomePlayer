class_name PathBindForm extends PanelContainer

# var _cell_height : float = 20.0

#当用户点击左侧的路径列表时触发该信号，参数为add_left_path时传递的路径
signal left_path_clicked(path : String)

#当用户拖动内容到右侧时的判断函数
var allow_drop_data_in_lrc_panel := Callable()
#用户拖动内容到右侧的处理函数，参数为(data, left_path, pre_right_data)，其中left_path和pre_right_data可能为null，表明拖放地点是外面
var process_drop_data_in_lrc_panel := Callable()

#{path : String, item_container : HBoxContainer}
var _left_path_dict := Dictionary()

var _item_ct_to_lrc_label_dict := Dictionary()

#记录当前选中的左侧控件
var _cur_selected_item_ct : HBoxContainer = null


func _ready() -> void:
	%VScrollBar.value_changed.connect(_update_vertical_pos)
	%HSplitContainer.dragged.connect(_update_HScrollBar)

	%HScrollBar_audio_path.value_changed.connect(_update_audio_page_horidiff)
	%HScrollBar_lrc_path.value_changed.connect(_update_lrc_page_horidiff)

	%audio_ref_Control.gui_input.connect(_audio_container_gui_input)

	%lrc_main_ctrl.drop_in_panel_availiable_func = func(at_position: Vector2, data: Variant):
		if not allow_drop_data_in_lrc_panel.is_valid():
			return false
		return allow_drop_data_in_lrc_panel.call(at_position, data)

	%lrc_main_ctrl.drop_in_panel_cb = func(at_position: Vector2, data: Variant):
		if process_drop_data_in_lrc_panel.is_valid():
			var ct := _get_lrc_ctrl_in_pos(at_position + %root_ctrl_lrc_path.position)
			if null == ct:
				process_drop_data_in_lrc_panel.call(data, null, null)
			else:
				var rightPATH = _get_lrc_ctrl_text(ct)
				for audio_ct in _item_ct_to_lrc_label_dict:
					var lrc_ct = _item_ct_to_lrc_label_dict[audio_ct]
					if lrc_ct == ct:
						for left_path in _left_path_dict:
							var ct_item = _left_path_dict[left_path]
							if ct_item == audio_ct:
								process_drop_data_in_lrc_panel.call(data, left_path, rightPATH)
								break
						break

	call_deferred("_update_HScrollBar", 0)
	pass


#向左边的列添加路径，格式为xx/xx/xx/xx/xxx.xx
func add_left_path(path : String, value : String = ""):
	# if _left_path_dict.has(path):
	# 	return
	var parts = _split_path_with_delimiter(path)
	# if _column_count() < parts.size():
	# 	_set_column_size(parts.size())

	_insert_parts(parts, path)
	if value.length() > 0:
		set_right_path_by_left_path(path, value)
	pass


#获取表单的行数
# func get_left_size() -> int:
# 	Utility.CriticalFail("not complete")
# 	return 0


# func for_each(cb : Callable):
# 	for path in _left_path_dict:
# 		cb.call(path)


# #通过下标向右边添加绑定的路径
# func set_right_path_by_index(left_index : int, path : String):
# 	pass
# func get_right_path_by_left(leftPath : String):
# 	pass


#通过左边path名向右边添加绑定的路径
func set_right_path_by_left_path(audio_path : String, lrc_path : String):
	var item_ct : HBoxContainer = _left_path_dict[audio_path]
	if item_ct:
		var label = _item_ct_to_lrc_label_dict[item_ct]
		_change_lrc_ctrl_text(label, lrc_path)
	pass


func all_left_paths() -> Array:
	return _left_path_dict.keys()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	var has_mouse_in_rect = Rect2(Vector2(0,0), size).has_point(get_local_mouse_position())
	if not has_mouse_in_rect:
		return

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				%VScrollBar.value -= 32
				pass
			MOUSE_BUTTON_WHEEL_DOWN:
				%VScrollBar.value += 32
		pass
	elif event is InputEventKey:
		get_viewport().set_input_as_handled()
		if event.is_pressed():
			match event.keycode:
				KEY_UP:
					if _cur_selected_item_ct:
						var cur_index = _get_item_ct_row_index(_cur_selected_item_ct)
						var pre_ct = _get_item_ct_in_row_index(cur_index - 1)
						if pre_ct:
							_select_item_ct(pre_ct)
					pass
				KEY_DOWN:
					if _cur_selected_item_ct:
						var cur_index = _get_item_ct_row_index(_cur_selected_item_ct)
						var pre_ct = _get_item_ct_in_row_index(cur_index + 1)
						if pre_ct:
							_select_item_ct(pre_ct)
					pass
	pass


func _make_item(text : String) -> VFloatContainer:
	var ct := VFloatContainer.new()
	var label := Label.new()
	ct.add_child(label)
	label.text = text
	ct.refrence_control = %audio_ref_Control
	label.mouse_filter = MOUSE_FILTER_IGNORE
	ct.mouse_filter = MOUSE_FILTER_IGNORE
	return ct


func _make_item_container(text : String) -> HBoxContainer:
	var text_item := _make_item(text)
	var ct := HBoxContainer.new()
	ct.add_child(text_item)
	ct.mouse_filter = MOUSE_FILTER_IGNORE
	return ct


func _get_item_text(ct : VFloatContainer) -> String:
	return ct.get_child(0).text


func _get_item_ct_text(ct : HBoxContainer) -> String:
	var vfct : VFloatContainer = ct.get_child(0)
	return _get_item_text(vfct)


func _get_child_container(ct : HBoxContainer) -> VBoxContainer:
	if ct.get_child_count() < 2:
		var cldct := VBoxContainer.new()
		cldct.mouse_filter = MOUSE_FILTER_IGNORE
		ct.add_child(cldct)
	return ct.get_child(1)


# func _has_child_container(ct : HBoxContainer) -> bool:
# 	#默认有两个子控件，一个是VFloatContainer，另一个是VBoxContainer(可能不存在)
# 	return ct.get_child_count() > 1


func _get_item_ct_child_count(ct : HBoxContainer) -> int:
	if ct.get_child_count() < 2:
		return 0

	return ct.get_child(1).get_child_count()



#分割path，但保留"/"字符
func _split_path_with_delimiter(path : String) -> PackedStringArray:
	var parts = path.split("/")
	var last = parts.get(parts.size() - 1)
	var rel := PackedStringArray()
	for i in range(parts.size() - 1):
		rel.append(parts[i] + "/")
	rel.append(last)
	return rel


func _insert_parts(path_parts : PackedStringArray, path : String):
	#进入这个函数时，假定_column_count()已经通过_set_column_size进行修改且必定大于path_parts.size()
	var cur_i : int = 0

	var cur_container : VBoxContainer = %VBoxContainer_audio
	for idx in range(path_parts.size()):
		var part_text = path_parts[idx]
		cur_i = idx
		var ct := _get_child_item_ct_in_text(cur_container, part_text)
		if null == ct:
			break

		cur_container = _get_child_container(ct)

	var insert_item_ct : HBoxContainer = null

	for idx in range(cur_i, path_parts.size()):
		var part_text = path_parts[idx]
		var new_item_ct = _make_item_container(part_text)
		_insert_item_ct_comp_text(cur_container, new_item_ct)
		insert_item_ct = new_item_ct
		cur_container = _get_child_container(new_item_ct)

	if null != insert_item_ct:
		_left_path_dict.set(path, insert_item_ct)
		#添加右侧的对象
		var index = _get_item_ct_row_index(insert_item_ct)
		# print("index: ", index)
		var lrc_ctrl = _make_lrc_ctrl()
		_item_ct_to_lrc_label_dict.set(insert_item_ct, lrc_ctrl)
		_insert_label_in_lrc_container(index, lrc_ctrl)

	call_deferred("_update_VScrollBar")
	call_deferred("_update_HScrollBar")
	pass


func _get_child_item_ct_in_text(ct : VBoxContainer, text : String) -> HBoxContainer:
	for child : HBoxContainer in ct.get_children():
		if _get_item_ct_text(child) == text:
			return child

	return null


func _insert_item_ct_comp_text(p_ct : VBoxContainer, ct_item : HBoxContainer):
	var text = _get_item_ct_text(ct_item)
	p_ct.add_child(ct_item)
	for child in p_ct.get_children():
		var cur_text = _get_item_ct_text(child)
		if _comp_text_custom(text, cur_text):
			var insert_index = child.get_index()
			p_ct.move_child(ct_item, insert_index)
			return


#对vft_list对象进行排序，结果返回
# func _sort_vft_list_by_text(vft_list : Array) -> Array:
# 	vft_list.sort_custom(func(a : VFloatContainer, b : VFloatContainer):
# 		return _get_item_text(a) < _get_item_text(b)
# 	)
# 	return vft_list
func _get_item_ct_row_index(item_ct : HBoxContainer) -> int:
	var row_index = 0
	var cur_ct := item_ct
	while null != cur_ct:
		var index = cur_ct.get_index()
		var pct : VBoxContainer = cur_ct.get_parent_control()
		for i in range(index):
			var upper_item_ct : HBoxContainer = pct.get_child(i)
			var lenth = _get_item_ct_row_size(upper_item_ct)
			row_index += lenth
		cur_ct = _get_parent_item_ct(cur_ct)

	return row_index


#获取排序在index上的叶子item_ct
func _get_item_ct_in_row_index(index : int) -> HBoxContainer:
	if index < 0 or index >= _left_path_dict.size():
		return null

	var cur_container : VBoxContainer = %VBoxContainer_audio
	var cur_index : int = 0

	while null != cur_container:
		for child : HBoxContainer in cur_container.get_children():
			if cur_index == index:
				if _get_item_ct_child_count(child) < 1:
					return child
				cur_container = _get_child_container(child)
				break

			var cur_child_size = _get_item_ct_row_size(child)
			if cur_index + cur_child_size > index:
				if _get_item_ct_child_count(child) < 1:
					Utility.CriticalFail()
					return null
				cur_container = _get_child_container(child)
				break

			cur_index += cur_child_size

		if null == cur_container:
			Utility.CriticalFail()
			break

	return null


func _get_item_ct_row_size(item_ct : HBoxContainer) -> int:
	var size_comclude = 0

	if _get_item_ct_child_count(item_ct) < 1:
		return 1

	var children = _get_child_container(item_ct).get_children()

	for ct : HBoxContainer in children:
		size_comclude += _get_item_ct_row_size(ct)

	return size_comclude


func _get_parent_item_ct(item_ct : HBoxContainer) -> HBoxContainer:
	var p = item_ct.get_parent()
	if p == %VBoxContainer_audio:
		return null
	return p.get_parent()


func _comp_text_custom(left : String, right : String) -> bool:
	var a : int = 1 if left.contains("/") else 0
	var b : int = 1 if right.contains("/") else 0
	if a == b:
		return left < right
	return a > b


func _insert_label_in_lrc_container(index : int, ctrl : Control):
	var max_count = %VBoxContainer_lrc.get_child_count()
	if index > max_count:
		Utility.CriticalFail()

	%VBoxContainer_lrc.add_child(ctrl)
	%VBoxContainer_lrc.move_child(ctrl, index)
	pass


#
# func _item_in_row_of_column(column_container : VBoxContainer, row : int)
func _update_HScrollBar(_diff : int = 0):
	var max_size = %VBoxContainer_audio.size.x
	var page_size = %PanelContainer_audio_path.size.x
	%HScrollBar_audio_path.max_value = max_size + 20
	%HScrollBar_audio_path.page = page_size

	max_size = %VBoxContainer_lrc.size.x
	page_size = %PanelContainer_lrc_path.size.x
	%HScrollBar_lrc_path.max_value = max_size + 20
	%HScrollBar_lrc_path.page = page_size
	pass


func _update_vertical_pos(y_diff : float):
	%root_ctrl_audio_path.position.y = -y_diff
	%root_ctrl_lrc_path.position.y = -y_diff

	_update_VScrollBar()
	pass

func _update_VScrollBar(_diff : int = 0):
	var max_size = %VBoxContainer_audio.size.y
	var page_size = %audio_ref_Control.size.y

	%VScrollBar.max_value = max_size + 40
	%VScrollBar.page = page_size
	pass


func _update_audio_page_horidiff(x_diff : float):
	_update_HScrollBar()
	%root_ctrl_audio_path.position.x = -x_diff
	pass


func _update_lrc_page_horidiff(x_diff : float):
	_update_HScrollBar()
	%root_ctrl_lrc_path.position.x = -x_diff
	pass


func _make_lrc_ctrl() -> PanelContainer:
	var bt := Button.new()
	bt.text = "  "
	bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var ct := PanelContainer.new()
	ct.add_child(bt)
	bt.mouse_filter = Control.MOUSE_FILTER_PASS
	ct.mouse_filter = Control.MOUSE_FILTER_PASS
	#todo 添加函数连接
	return ct


func _change_lrc_ctrl_text(ctrl : PanelContainer, text : String):
	ctrl.get_child(0).text = text


func _get_lrc_ctrl_text(ctrl : PanelContainer) -> String:
	return ctrl.get_child(0).text


func _audio_container_gui_input(input : InputEvent):
	if input is InputEventMouseButton:
		match input.button_index:
			MOUSE_BUTTON_LEFT:
				if input.pressed:
					var ct = _get_item_ct_in_pos(%VBoxContainer_audio.get_local_mouse_position())
					if ct:
						_select_item_ct(ct)
					pass
		pass
	pass


#获取pos处的item_ct，其中pos是%VBoxContainer_audio的本地坐标
func _get_item_ct_in_pos(pos : Vector2) -> HBoxContainer:
	if pos.y > %VBoxContainer_audio.size.y or pos.y < 0:
		return null

	pos = %VBoxContainer_audio.global_position + pos
	var y_diff = pos.y
	var children = %VBoxContainer_audio.get_children()
	while null != children:
		for ct : HBoxContainer in children:
			var point = Vector2(ct.global_position.x + 1.0, y_diff)
			var rect = ct.get_global_rect()
			if rect.has_point(point):
				if _get_item_ct_child_count(ct) < 1:
					return ct
				children = _get_child_container(ct).get_children()
				# if _has_child_container(ct):
				# 	children = _get_child_container(ct).get_children()
				# 	if children.is_empty():
				# 		return ct
				# else:
				# 	return ct
				pass
	return null


func _select_item_ct(item_ct : HBoxContainer):
	_cur_selected_item_ct = item_ct
	if null == item_ct:
		%select_ColorRect.hide()
		%select_ColorRect_lrc.hide()
		return

	%select_ColorRect.show()
	%select_ColorRect_lrc.show()
	var pp = %select_ColorRect.get_parent_control()
	var rct = item_ct.global_position
	%select_ColorRect.position = Vector2(0, rct.y - pp.global_position.y)
	%select_ColorRect.size = Vector2(9999, item_ct.size.y)
	%select_ColorRect_lrc.position = Vector2(0, rct.y - pp.global_position.y)
	%select_ColorRect_lrc.size = Vector2(9999, item_ct.size.y)

	for path in _left_path_dict:
		if _left_path_dict[path] == item_ct:
			left_path_clicked.emit(path)
			break


#获取pos处的lrc contorl，其中pos是%root_ctrl_lrc_path本地坐标
func _get_lrc_ctrl_in_pos(pos : Vector2) -> PanelContainer:
	for ct : PanelContainer in %VBoxContainer_lrc.get_children():
		if ct.get_rect().has_point(pos):
			return ct
	return null
