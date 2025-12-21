extends MarginContainer

var current_select_picture_content : SelectPicContent
# var current_button_name : String

var button_to_info : Dictionary = Dictionary()

#辅助按钮拖动的变量
var _selected_button : SimpleButton = null
var _clicked_button : SimpleButton = null
var _clicked_button_diff_pos : Vector2   #相对坐标
var _clicked_mouse_emit_pos : Vector2   #相对坐标

var _need_refresh : bool = false

#记录是否使用自定义指针
var _is_using_custome_cursor := false

#记录被复制的信息
var _duplicate_info := Dictionary()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%PicContainer.drop_in_panel_availiable_func = func(_at_position: Vector2, data: Variant):
		if null == current_select_picture_content:
			return false
		return _is_pic_dropdata(data)

	%PicContainer.drop_in_panel_cb = func(_at_position: Vector2, data: Variant):
		var path = data[0]
		print(path)
		var pic = TextureCenter.get_picture(path)
		current_select_picture_content.usedTexturePath = Utility.cut_file_path(path)
		_set_picture(pic)

	%picture.gui_input.connect(_pictrue_gui_input)

	%Button_add_normal.pressed.connect(_add_button_normal)

	%param_container.get_value = func():
		if null == current_select_picture_content or null == _selected_button:
			return null

		return button_to_info[_selected_button]

	%param_container.value_changed.connect(_param_updated)

	%param_container.hide()

	visibility_changed.connect(func():
		if visible and _need_refresh:
			_show_pic_content()
	)

	%DropLabel.drop_in_panel_availiable_func = func(_at_position: Vector2, data: Variant):
		if null == current_select_picture_content:
			return false
		if null == _selected_button:
			return false

		if data[2] == FileTree.AssetType.Picture:
			return true
		return false

	%DropLabel.drop_in_panel_cb = func(_at_position: Vector2, data: Variant):
		var picture_path = data[0]
		_set_cur_buton_picture(Utility.cut_file_path(picture_path))
		pass
	pass # Replace with function body.


func _is_pic_dropdata(data : Variant) -> bool:
	if not typeof(data) == TYPE_ARRAY:
		return false

	if data.size() < 3:
		return false

	return data[2] == FileTree.AssetType.Picture


func _set_picture(pic):
	%picture.texture = pic
	if null != pic:
		#%AspectRatioContainer.size = pic.get_size()
		%picture.size = pic.get_size()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return

	var has_mouse_in_rect = Rect2(Vector2(0,0), size).has_point(get_local_mouse_position())

	if has_mouse_in_rect:
		if Input.is_key_pressed(KEY_ALT):
			Input.set_custom_mouse_cursor(preload("res://editor/icon/delete_16.png"), Input.CURSOR_ARROW, Vector2(8,8))
			_is_using_custome_cursor = true
			#mouse_default_cursor_shape = Control.CURSOR_CROSS
			#Input.set_default_cursor_shape(Input.CURSOR_CROSS)
		else:
			Input.set_custom_mouse_cursor(null)
			_is_using_custome_cursor = false
	elif _is_using_custome_cursor:
		Input.set_custom_mouse_cursor(null)
		_is_using_custome_cursor = false
	pass


func set_current_pic_content(ctt : SelectPicContent):
	if null == ctt:
		_set_picture(null)
		return

	if ctt == current_select_picture_content:
		return

	current_select_picture_content = ctt

	if visible:
		_need_refresh = false
		_show_pic_content()
	else:
		_need_refresh = true
	pass


#显示current_select_picture_content
func _show_pic_content():
	#清空之前的内容
	for button : SimpleButton in button_to_info:
		%picture.remove_child(button)
		button.queue_free()

	button_to_info.clear()
	%param_container.hide()
	_selected_button = null

	if current_select_picture_content.usedTexturePath.is_empty():
		_set_picture(null)
	else:
		var pic = TextureCenter.get_picture(current_select_picture_content.usedTexturePath)
		_set_picture(pic)
		pass

	#todo 遍历nextNodes_button对象来构造图像
	for bname in current_select_picture_content.buton_index:
		var info = current_select_picture_content.buton_index[bname]
		_create_button_from_info(info)

	current_select_picture_content.before_delete_sig.connect(
		func(_ctt):
			if _ctt == current_select_picture_content:
				current_select_picture_content = null
				_set_picture(null)
	)
	pass


func _add_button_normal():
	if null == current_select_picture_content:
		return

	if null != _selected_button:
		%param_container.update()

	var names = current_select_picture_content.buton_index.keys()
	var newName = Utility.check_no_repeat_name("empty", names)

	var newInfo = SelectPicContent.SelectButtonInfo.new()
	newInfo.name = newName
	newInfo.name_as_text = true
	newInfo.text = newInfo.name
	newInfo.pos = Vector2.ONE * 0.5
	newInfo.size = Vector2(0.1, 0.05)
	newInfo.bgcolor = Color.DIM_GRAY
	newInfo.fontcolor = Color.WHITE
	newInfo.isPicture = false

	current_select_picture_content.buton_index.set(newName, newInfo)

	_selected_button  = _create_button_from_info(newInfo)

	%param_container.refresh()
	%param_container.show()
	pass


func _create_button_from_info(info : SelectPicContent.SelectButtonInfo) -> SimpleButton:
	var addone = SimpleButton.create_button_from_button_info(%picture, info)

	button_to_info.set(addone, info)
	addone.pressed.connect(_select_change)
	addone.button_gui_input.connect(_button_gui_input)

	addone.update_from_info(info)

	return addone


func _select_change(button : SimpleButton):
	var info : SelectPicContent.SelectButtonInfo = button_to_info[button]
	if null == info:
		printerr("wc, 这是什么鬼")
		Utility.CriticalFail()
		return

	%button_name.remove_theme_color_override("font_color")
	# if not current_button_name.is_empty():
	# 	%param_container.update()

	_selected_button = button
	%param_container.show()
	%param_container.refresh()
	# print("emit button")
	button.move_to_front()

	if not info.picpath.is_empty():
		%DropLabel.text = info.picpath
	else:
		%DropLabel.text = tr("drag here set", "select_pic_editor")
	pass


func _pictrue_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				if event.is_pressed():
					if not _duplicate_info.is_empty():
						var list := Array()
						var pos = event.position
						list.append(CusContentMenu.bt(tr("paste button"), func():
							var info = SelectPicContent.SelectButtonInfo.new()
							SelectPicContent.unserialize_button_info(_duplicate_info, info)
							var names = current_select_picture_content.buton_index.keys()
							var newName = Utility.check_no_repeat_name("empty", names)
							info.name = newName
							info.pos = (pos / %picture.size).clampf(0.0, 1.0)
							_create_button_from_info(info)
							pass
						))
						CusContentMenu.create(self, get_global_mouse_position(), list)
	pass


func _button_gui_input(button : SimpleButton, event : InputEvent):
	# if event is InputEventMouseButton:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				#用户请求删除节点
				if Input.is_key_pressed(KEY_ALT) and event.pressed:
					_delete_button(button)
					return

				if event.pressed:
					_clicked_button = button
				else:
					_clicked_button = null

				_clicked_mouse_emit_pos = _picture_mouse_anchor()
				_clicked_button_diff_pos = _button_anchor_pos(button) - _clicked_mouse_emit_pos
				pass
			MOUSE_BUTTON_RIGHT:
				#用户呼叫右键菜单
				if event.pressed:
					var list := Array()
					list.append(CusContentMenu.bt(tr("copy"), func():
						var info = button_to_info[button]
						_duplicate_info = SelectPicContent.serialize_button_info(info)
						pass
					))

					if not _duplicate_info.is_empty():
						list.append(CusContentMenu.bt(tr("paste button param"), func():
							var info = SelectPicContent.SelectButtonInfo.new()
							SelectPicContent.unserialize_button_info(_duplicate_info, info)
							var custom_info = button_to_info[button]
							custom_info.size = info.size
							custom_info.bgcolor = info.bgcolor
							custom_info.name_as_text = info.name_as_text
							custom_info.text = info.text
							custom_info.fontcolor = info.fontcolor
							custom_info.isPicture = info.isPicture
							custom_info.picpath = info.picpath
							button.update_from_info(custom_info)
							pass
						))

					CusContentMenu.create(self, get_global_mouse_position(), list)
		pass

	elif event is InputEventMouseMotion:
		if _clicked_button == button:
			var _curmouse_pos = _picture_mouse_anchor()
			var requiPos = _clicked_button_diff_pos + _curmouse_pos
			var info : SelectPicContent.SelectButtonInfo = button_to_info[button]
			requiPos = requiPos.clampf(0.0, 1.0)
			info.pos = (requiPos * 100).round() * 0.01
			_clicked_button.update_from_info(info)

			%param_container.refresh()
		pass
	pass


func _mouse_pos_to_anchor_pos_picture(pos : Vector2):
	return pos / %picture.size


func _picture_mouse_anchor() -> Vector2:
	return %picture.get_local_mouse_position() / %picture.size


func _button_anchor_pos(button : SimpleButton) -> Vector2:
	return Vector2(button.anchor_left, button.anchor_top)


func _delete_button(button : SimpleButton):
	#todo
	if button == _selected_button:
		_selected_button = null

	if button == _clicked_button:
		_clicked_button = null

	print("delete require")
	%param_container.hide()
	var select_info = button_to_info[button]
	current_select_picture_content.delete_button_info(select_info.name)
	button_to_info.erase(button)
	%picture.remove_child(button)
	pass


func _param_updated(param : String, value):
	if null == _selected_button:
		return

	var cur_button_info = button_to_info[_selected_button]

	if typeof(cur_button_info.get(param)) == typeof(value):
		if "name" == param:
			#检查名称是否重复
			if value.is_empty():
				return

			var names = current_select_picture_content.buton_index.keys()
			if value in names:
				%button_name.add_theme_color_override("font_color", Color.RED)
			else:
				%button_name.remove_theme_color_override("font_color")
				var prename = cur_button_info.name
				current_select_picture_content.update_button_index_key(prename, value)
				cur_button_info.name = value
				current_select_picture_content.button_name_change_signal.emit(prename, value)
		else:
			cur_button_info.set(param, value)

		if null != _selected_button:
			_selected_button.update_from_info(cur_button_info)
	else:
		printerr("param set error")

	pass


# func _update_button_from_info(button : SimpleButton, info : SelectPicContent.SelectButtonInfo):
# 	button.anchor_left = info.pos.x
# 	button.anchor_top = info.pos.y
# 	button.anchor_right = info.pos.x + info.size.x
# 	button.anchor_bottom = info.pos.y + info.size.y
# 	if info.name_as_text:
# 		button.text = info.name
# 	else:
# 		button.text = info.text

# 	button.change_color(info.bgcolor)
# 	button.change_font_color(info.fontcolor)
func _set_cur_buton_picture(pic_path : String):
	if null == _selected_button:
		return

	%DropLabel.text = pic_path
	var cur_button_info : SelectPicContent.SelectButtonInfo = button_to_info[_selected_button]
	cur_button_info.picpath = pic_path
	_selected_button.update_from_info(cur_button_info)
	pass
