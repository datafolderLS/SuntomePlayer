extends Control

@onready var state_panel : StatePanel= get_node("%StatePanel")


var start_node : StateNode
var sourou_node : StateNode

var _cur_select_node : StateNode = null

var _context_func : Callable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#绑定StatePanel的拖放事件，删除处理
	state_panel.drop_in_panel_availiable_func = Callable(self, "_panel_drop_check")
	state_panel.drop_in_panel_cb = Callable(self, "_panel_drop_process")
	state_panel.node_delete_check_func = Callable(self, "_node_delete_check")

	#允许所有线条删除
	state_panel.line_delete_check_func = func(_value): return true

	#绑定获取拖拽线标识的函数
	state_panel.req_line_drag_label_text_func = Callable(self, "_line_start_drag")

	#param_panel.hide()
	#读取SuntomeGlobal的信息，创建各种节点
	#构造开始节点
	var start = state_panel.new_node()
	var _content = SuntomContent.Create(start, SuntomeGlobal.begin_node, Callable(self, "_update_node_line_index_info"))
	_change_node_to_trans(start)
	var lab = start.get_ctt()
	lab.text = "Start"
	# start.get_container().add_child(lab)
	start.position = SuntomeGlobal.begin_node.position
	start_node = start

	#构造早漏节点
	var sourou = state_panel.new_node()
	_content = SuntomContent.Create(sourou, SuntomeGlobal.sourou_node, Callable(self, "_update_node_line_index_info"))
	_change_node_to_trans(sourou)
	lab = sourou.get_ctt()
	lab.text = "SouRou"
	sourou.position = SuntomeGlobal.sourou_node.position
	sourou_node = sourou

	%ButtonAddNode.pressed.connect(_add_state_node)
	%ButtonAddTrans.pressed.connect(_add_trans_node)
	%ButtonAddSetting.pressed.connect(_add_setting_node)

	#右键菜单
	%ctt_button.pressed.connect(func() : _context_func.call())
	%ctt_root_control.hide()
	%ctt_root_control.gui_input.connect(
		func(event: InputEvent):
			if event is InputEventMouseButton:
				%ctt_root_control.hide()
			pass
	)


	#读取SuntomeGlobal的内容并初始化节点信息
	_fresh_panel_from_global()

	state_panel.line_connect_check_func = Callable(self, "_line_connect_check")

	state_panel.node_connected.connect(_process_node_connect)
	state_panel.node_disconnected.connect(_process_node_disconnect)
	state_panel.node_deleted.connect(_process_node_delete)
	state_panel.node_selected.connect(_node_select_change)
	state_panel.context_menu_req.connect(_context_menu_show)
	state_panel.node_pos_updated.connect(_node_pos_update)
	pass # Replace with function body.


func _fresh_panel_from_global():
	#首先构造所有的节点
	var uid_to_node := Dictionary() #存储uid到StateNode的临时映射对象

	for uid in SuntomeGlobal.suntome_nodes:
		var stmnode : SuntomeNodeBase = SuntomeGlobal.suntome_nodes[uid]
		var node = state_panel.new_node()
		node.position = stmnode.position
		uid_to_node.set(uid, node)

		if stmnode is SuntomeNode:
			SuntomContent.Create(node, stmnode, Callable(self, "_update_node_line_index_info"))
			if stmnode.is_transit_node:
				_change_node_to_trans(node)
		elif stmnode is SuntomeSelectPictNode:
			SuntomeSPicContent.create_ctt_from_pic_node(node, stmnode,
				Callable(self, "_update_node_line_index_info"),
				Callable(self, "_select_pic_ctt_line_delete_req")
			)
		elif stmnode is SuntomeParaNode:
			SuntomeParaNodeContent.create_ctt_from_para_node(node, stmnode)
		else:
			printerr("stmnode type error")

	#其次连接所有的节点
	for uid in SuntomeGlobal.suntome_nodes:
		var stmnode : SuntomeNodeBase = SuntomeGlobal.suntome_nodes[uid]
		var left_node = uid_to_node[uid]
		for right_uid in stmnode.nextNodes.keys():
			var right_node = uid_to_node[right_uid]
			state_panel.connect_node(left_node, right_node)

	#处理start和sourou
	for left_node in init_nodes():
		var stmnode = get_node_SuntomeNode(left_node)
		for right_uid in stmnode.nextNodes.keys():
			var right_node = uid_to_node[right_uid]
			state_panel.connect_node(left_node, right_node)
		pass

	#更新连接的标签信息
	for node : StateNode in uid_to_node.values():
		_update_node_line_index_info(node)

	for node : StateNode in init_nodes():
		_update_node_line_index_info(node)
	pass


func init_nodes() -> Array:
	return [start_node, sourou_node]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _add_state_node() -> StateNode:
	var next = state_panel.new_node()
	#让next处在画面中央
	next.position = state_panel.pos_map(state_panel.size / 2)
	var _content = _add_content(next)
	return next


func _add_trans_node() -> StateNode:
	var node = _add_state_node()
	_change_node_to_trans(node)
	return node


func _add_setting_node() -> StateNode:
	var next = state_panel.new_node()
	next.position = state_panel.pos_map(state_panel.size / 2)
	var newNode := SuntomeParaNode.new_node()
	newNode.position = next.position
	SuntomeGlobal.suntome_nodes.set(newNode.uid, newNode)
	var _content = SuntomeParaNodeContent.create_ctt_from_para_node(next, newNode)
	return next


func _change_node_to_trans(node : StateNode):
	var ctt = node.get_ctt()
	if ctt is SuntomContent:
		ctt.ref_suntome_node.is_transit_node = true
		node.get_container().remove_child(ctt)
		node.custom_data = ctt
		var lab = Label.new()
		lab.text = "Port"
		node.get_container().add_child(lab)
		node.size = Vector2(60, 60)


func _change_node_to_content(node : StateNode):
	if node in init_nodes():
		return

	var ctt = node.get_ctt()
	if ctt is Label:
		var stm = get_node_SuntomeNode(node)
		stm.is_transit_node = false
		node.get_container().remove_child(ctt)
		node.get_container().add_child(node.custom_data)
		node.size = Vector2(60, 60)


func _panel_drop_check(_at_position: Vector2, data: Variant)-> bool:
	if typeof(data) == TYPE_ARRAY and data.size() <= 2:
		if SuntomeGlobal.select_pic_contents.keys().has(data[0]):
			return true

	if typeof(data) == TYPE_ARRAY and data[2] == FileTree.AssetType.Picture:
		return true

	if typeof(data) == TYPE_STRING and SuntomeGlobal.sound_object_contents.keys().has(data):
		return true
	return false


func _panel_drop_process(_at_position: Vector2, data: Variant):
	#处理选择图片SelectPic的拖放逻辑
	if typeof(data) == TYPE_ARRAY and data.size() <= 2:
		var next = state_panel.new_node()
		next.position = state_panel.pos_map(state_panel.get_local_mouse_position())
		var _ctt = _add_spic_content(next, SuntomeGlobal.select_pic_contents[data[0]])
	#处理普通图片的拖放逻辑
	elif typeof(data) == TYPE_ARRAY and data[2] == FileTree.AssetType.Picture:
		var next = state_panel.new_node()
		next.position = state_panel.pos_map(state_panel.get_local_mouse_position())
		var content = _add_content(next)
		content.set_picture_path(data[0])
	#处理普通音频的拖放逻辑
	elif typeof(data) == TYPE_ARRAY and data[2] == FileTree.AssetType.Sound:
		pass
	#处理音频对象的拖放逻辑
	elif typeof(data) == TYPE_STRING and SuntomeGlobal.sound_object_contents.keys().has(data):
		var next = state_panel.new_node()
		var content = _add_content(next)
		next.position = state_panel.pos_map(state_panel.get_local_mouse_position())
		content.set_sound_obj_content_name(data)
		pass
	pass


func _node_delete_check(node : StateNode) -> bool:
	if node in init_nodes():
		return false
	return true


func _add_content(node : StateNode) -> SuntomContent:
	var newNode := SuntomeNode.new_node()
	newNode.position = node.position
	SuntomeGlobal.suntome_nodes.set(newNode.uid, newNode)
	var content = SuntomContent.Create(node, newNode, Callable(self, "_update_node_line_index_info"))
	return content


func _add_spic_content(node : StateNode, spc : SelectPicContent) -> SuntomeSPicContent:
	var newNode := SuntomeSelectPictNode.new_node()
	newNode.position = node.position
	SuntomeGlobal.suntome_nodes.set(newNode.uid, newNode)
	newNode.usedSelectPic = spc
	var ctt = SuntomeSPicContent.create_ctt_from_pic_node(node, newNode,
		Callable(self, "_update_node_line_index_info"),
		Callable(self, "_select_pic_ctt_line_delete_req")
	)
	return ctt


func get_node_SuntomeNode(node : StateNode) -> SuntomeNodeBase:
	return get_node_ctt(node).ref_suntome_node


func _line_start_drag(from : StateNode) -> String:
	return get_node_ctt(from).get_drag_line_info()


#获取node存储的content对象，例如SuntomContent等
func get_node_ctt(node : StateNode):
	var ctt = node.get_ctt()
	if ctt is Label:
		return node.custom_data
	return ctt


func _line_connect_check(from : StateNode, to : StateNode)->bool:
	if to in init_nodes():
		return false

	var left = get_node_ctt(from)
	return left.line_connect_check()


func _process_node_connect(from : StateNode, to : StateNode):
	var lctt = get_node_ctt(from)
	var right = get_node_ctt(to).ref_suntome_node
	lctt.process_node_connect(right)
	_show_node_param(from)
	_update_node_line_index_info(from)


func _process_node_disconnect(from : StateNode, to : StateNode):
	var lctt = get_node_ctt(from)
	var right = get_node_ctt(to).ref_suntome_node

	lctt.process_node_disconnect(right)

	_show_node_param(from)
	_update_node_line_index_info(from)


func _update_node_line_index_info(from : StateNode):
	var lctt = get_node_ctt(from)
	var lines = state_panel.lines_from_node(from)
	var fc = lctt.get_connect_line_lable()
	for line in lines:
		var text = fc.call(get_node_SuntomeNode(line.end))
		line.set_label(text)


func _process_node_delete(node : StateNode):
	var ctt = get_node_SuntomeNode(node)
	SuntomeGlobal.suntome_nodes.erase(ctt.uid)

	if node == _cur_select_node:
		%param_container.hide()
	pass


func _show_node_param(node : StateNode):
	var ctt = get_node_ctt(node)
	%param_container.show()
	ctt.show_node_param(%param_container)
	pass


#用户选中的节点发生变化信号槽函数
func _node_select_change(selected_node : StateNode, _pre_selected : StateNode):
	_cur_select_node = selected_node
	_show_node_param(selected_node)
	pass


func _context_menu_show(emit_node : StateNode, _pos : Vector2):
	if emit_node in init_nodes():
		return

	var left = emit_node.get_ctt()
	if left is SuntomeSPicContent:
		return

	#显示右键菜单
	print("context menu show")
	%ctt_root_control.show()
	%contextmenu.position = get_local_mouse_position()

	#优化位置
	var rr = get_rect()
	var rc = %contextmenu.get_rect()
	if rr.end.y < rc.end.y:
		var diff = rc.end.y - rr.end.y
		%contextmenu.position.y -= diff

	_context_func = func():
		var ctt = get_node_SuntomeNode(emit_node)
		#print("call once")
		%ctt_root_control.hide()
		if ctt.is_transit_node:
			_change_node_to_content(emit_node)
		else:
			_change_node_to_trans(emit_node)
	pass


func _select_pic_ctt_line_delete_req(node : StateNode, other : SuntomeNodeBase):
	for line : StateLine in state_panel.lines_from_node(node):
		if other == get_node_SuntomeNode(line.end):
			state_panel.disconnect_line(line)
			break
	pass


func _node_pos_update(emit_node : StateNode, pos : Vector2):
	var stm = get_node_SuntomeNode(emit_node)
	stm.position = pos
	pass
