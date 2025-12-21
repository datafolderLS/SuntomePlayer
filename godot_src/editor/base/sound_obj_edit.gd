extends Control

@onready var GraphEd : GraphEdit = get_node("GraphEdit")
@onready var node_out : GraphNode = get_node("GraphEdit/outnode")
@onready var param_container : VBoxContainer = get_node("PanelContainer/paramContainer")

var current_edit_node : SoundObjContent = null

var _presize : Vector2 = Vector2(-1,-1)

var _is_using_custome_cursor := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GraphEd.show_grid = false
	GraphEd.show_grid_buttons = false
	GraphEd.show_menu = false
	GraphEd.connection_request.connect(_connection_request)
	GraphEd.end_node_move.connect(_check_all_node_position_and_update)
	GraphEd.gui_input.connect(_graphed_gui_input)


	LocalizationCenter.LocalChanged.connect(
		func():
			var paramctrl = param_container.get_child(0)
			if paramctrl:
				paramctrl.set_text(tr("play method", "sound_obj_edit"))
	)

	pass # Replace with function body.


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

	if is_visible_in_tree():
		if _presize.x < 0:
			_presize = size
		elif _presize != size:
			_resize_cb(_presize)
			_presize = size
	else:
		_presize = Vector2(-1,-1)
	pass


#和SoundObjList进行关联
func connect_sound_obj_list(sol : ObjList):
	sol.select_change.connect(
		func(select_name : String):
			if SuntomeGlobal.sound_object_contents.has(select_name):
				var obj = SuntomeGlobal.sound_object_contents[select_name]
				set_sound_object(obj)
			pass
	)
	pass


#基于sobjcontent的内容刷新页面
func set_sound_object(sobj : SoundObjContent):
	#解绑当前对象
	if null != current_edit_node:
		current_edit_node.name_change_cb = Callable()
		current_edit_node.before_delete_cb = Callable()
		Utility.remove_all_child(param_container)

	#清空多余节点
	_clear_node()

	current_edit_node = sobj

	node_out.position_offset = sobj.out_offset_pos
	node_out.visible = true
	node_out.title = sobj.name

	for node in sobj.sound_nodes:
		var n = _add_sound_context(_make_node(node.path))
		n.position_offset = node.offset_pos
		if node.has_connected:
			GraphEd.connect_node(n.name, 0, node_out.name, 0)


	current_edit_node.name_change_cb = func(sobj_ : SoundObjContent):
		if sobj_ == current_edit_node:
			node_out.title = current_edit_node.name

	current_edit_node.before_delete_cb = func(sobj_ : SoundObjContent):
		if sobj_ == current_edit_node:
			_clear_node()
			node_out.title = ""

	#往paramContainer添加内容
	var ctrl = _construct_param_control(current_edit_node)
	param_container.add_child(ctrl)
	pass


func _construct_param_control(value) -> Control:
	if value is SoundObjContent:
		var paramctrl = preload("res://editor/base/param_ctrl.tscn").instantiate()
		paramctrl.set_text(tr("play method", "sound_obj_edit"))
		# paramctrl.container().add_child()
		var ctrl := Utility.make_enum_option_button(Utility.RandomHelper.Method)
		ctrl.select(value.play_method)
		paramctrl.container().add_child(ctrl)
		ctrl.item_selected.connect(
			func(id : int):
				@warning_ignore_start("INT_AS_ENUM_WITHOUT_CAST")
				current_edit_node.play_method = id
				@warning_ignore_restore("INT_AS_ENUM_WITHOUT_CAST")
				pass
		)

		return paramctrl

	return null


func _clear_node():
	#删除除了node_out以外的其他节点
	var allChild = GraphEd.get_children()
	for n in allChild :
		if n != node_out and n is GraphNode:
			GraphEd.remove_child(n)
			n.queue_free()
	pass


func _make_node(use_name : String):
	var node = GraphNode.new()
	node.title = use_name
	GraphEd.add_child(node)
	return node


func _add_sound_context(node : GraphNode) -> GraphNode:
	var content = Label.new()
	content.text = tr("sound", "sound_obj_edit")
	content.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	node.add_child(content)
	node.set_slot_enabled_right(0, true)
	node.set_slot_type_right(0, 0)

	#添加鼠标点击的处理函数，响应用户的删除操作
	node.gui_input.connect(
		func(input : InputEvent):
			if not input is InputEventMouseButton:
				return

			if input.button_index == MOUSE_BUTTON_LEFT and input.pressed and Input.is_key_pressed(KEY_ALT):
				_delete_node(node)
			pass
	)

	return node


#允许的metadata应该是[path, FileTree.Type.File, FileTree.AssetType.Sound]的文件形式，且第三个成员是FileTree.AssetType.Sound
func _can_drop_data(_position, data):
	if null == current_edit_node:
		return false

	if typeof(data) == TYPE_ARRAY and data[1] == FileTree.Type.Folder:
		return true

	var rel = typeof(data) == TYPE_ARRAY and data[2] == FileTree.AssetType.Sound
	return rel


func _drop_data(dposition, data):
	if data[1] == FileTree.Type.Folder:
		var path = Utility.cut_file_path(data[0])
		var pathlist := Array()

		FileTree.scan_folder(path, func(filepath, type : FileTree.Type):
			if FileTree.Type.File != type:
				return
			if Utility.file_suffix(filepath) in GlobalSetting.SurportSoundTypes:
				pathlist.append(filepath)
			pass
		)

		var beginPos = (dposition + GraphEd.scroll_offset) / GraphEd.zoom
		for spath in pathlist:
			_add_sound_node_in_pos(spath, beginPos)
			beginPos += Vector2(0, 120)
		pass
	else:
		_add_sound_node_in_pos(data[0], (dposition + GraphEd.scroll_offset) / GraphEd.zoom)
	pass


func _add_sound_node_in_pos(path : String, pos : Vector2) -> GraphNode:
	path = Utility.cut_file_path(path)
	var node = _add_sound_context(_make_node(path))
	node.position_offset = pos
	#修改current_edit_node的数据
	var newNodeInfo = SoundObjContent.NodeInfo.new()
	newNodeInfo.offset_pos = node.position_offset
	newNodeInfo.path = path
	newNodeInfo.has_connected = true
	current_edit_node.sound_nodes.append(newNodeInfo)

	GraphEd.connect_node(node.name, 0, node_out.name, 0)
	return node


static func _find_child_by_name(parent : Node, name_ : String) -> Node:
	var nodes = parent.get_children()
	for n in nodes:
		if name_ == n.name:
			return n
	return null


func _connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	print("connect req ", from_node, from_port, to_node, to_port)
	GraphEd.connect_node(from_node, from_port, to_node, to_port)
	var node = _find_child_by_name(GraphEd, from_node)
	if node is GraphNode:
		var cur = current_edit_node.get_sound_node_by_path(node.title)
		if null == cur:
			print("critical error")
			return

		cur.has_connected = true
		return

	print("critical error")
	pass


#检查current_edit_node的信息，并基于该信息更新GraphEd中各节点的坐标
func _check_all_node_position_and_update():
	if null == current_edit_node:
		return

	#更新node_out的坐标
	current_edit_node.out_offset_pos = node_out.position_offset

	#更新每一个对象的坐标
	var allChild = GraphEd.get_children()
	for n in allChild :
		if n != node_out and n is GraphNode:
			var info = current_edit_node.get_sound_node_by_path(n.title)
			if null == info:
				print("error: cant find ", n.title, " in sound_nodes")
				continue
			info.offset_pos = n.position_offset
	pass


func _delete_node(node : GraphNode):
	GraphEd.remove_child(node)
	var path = node.title
	node.queue_free()

	var index = current_edit_node.sound_nodes.find_custom(
		func(data : SoundObjContent.NodeInfo):
			return data.path == path
	)

	current_edit_node.sound_nodes.remove_at(index)
	pass


func _graphed_gui_input(input : InputEvent):
	if input is InputEventMouseButton:
		match input.button_index:
			MOUSE_BUTTON_RIGHT:
				if input.is_pressed():
					var node = _get_node_in_pos(input.global_position)
					if null == node:
						return

					var list := Array()
					if node.selected:
						list.append(
							CusContentMenu.bt("delete", func():
							for check : GraphNode in _get_all_node():
								if check.selected:
									_delete_node(check)
							)
						)
						pass
					else:
						list.append(CusContentMenu.bt("delete", func():
							_delete_node(node)
						)
						)
						pass

					CusContentMenu.create(self, get_global_mouse_position(), list)
					pass
				pass
	pass


func _get_node_in_pos(global_pos : Vector2) -> GraphNode:
	for check_node : GraphNode in _get_all_node():
		var rect = check_node.get_global_rect()
		if rect.has_point(global_pos):
			return check_node

	# var dict = GraphEd.get_closest_connection_at_point(graphed_pos)
	# if dict.is_empty():
	# 	return null
	# var node = _find_child_by_name(GraphEd, dict["from_node"])
	# if not node is GraphNode:
	# 	Utility.CriticalFail()
	# 	return null

	return null


func _get_all_node() -> Array:
	return GraphEd.get_children().filter(func(element):
		return element is GraphNode and element != node_out
	)


func _resize_cb(pre_size : Vector2):
	var change = size - pre_size
	print(change)
	GraphEd.scroll_offset -= change * 0.5
	pass
