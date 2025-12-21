extends Control

@onready var state_panel : StatePanel= get_node("%StatePanel")


var start_node : StateNode
var sourou_node : StateNode

var _cur_select_node : StateNode = null

static var NormalNodeFuncMap = {
	SuntomeParaNode.normal_key() : [SuntomeParaNode, SuntomeParaNodePanel],
	SuntomeCountCheckNode.normal_key(): [SuntomeCountCheckNode, SuntomeCountCheckNodePanel],
	SuntomeTimeBeginNode.normal_key(): [SuntomeTimeBeginNode, SuntomeTimeBeginNodePanel],
	SuntomeTimeCheckNode.normal_key(): [SuntomeTimeCheckNode, SuntomeTimeCheckNodePanel],
}


var _cliped_data := String()

#记录当前正在播放的节点
var _preplayed_node : StateNode = null

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
	lab.text = tr("Start")
	# start.get_container().add_child(lab)
	start.position = SuntomeGlobal.begin_node.position
	start_node = start

	#构造早漏节点
	var sourou = state_panel.new_node()
	_content = SuntomContent.Create(sourou, SuntomeGlobal.sourou_node, Callable(self, "_update_node_line_index_info"))
	_change_node_to_trans(sourou)
	lab = sourou.get_ctt()
	lab.text = tr("SouRou")
	sourou.position = SuntomeGlobal.sourou_node.position
	sourou_node = sourou

	%ButtonAddNode.pressed.connect(_add_state_node)
	%ButtonAddTrans.pressed.connect(_add_trans_node)

	# %ButtonAddSetting.pressed.connect(_add_setting_node)
	# %ButtonAddCountCheck.pressed.connect(_add_count_check_node)

	# %ButtonAddSetting.pressed.connect(func(): _add_normal_node(SuntomeParaNode.normal_key()))
	# %ButtonAddCountCheck.pressed.connect(func(): _add_normal_node(SuntomeCountCheckNode.normal_key()))

	%ButtonAddOther.get_popup().index_pressed.connect(
		func(bindex : int):
			var id = %ButtonAddOther.get_popup().get_item_id(bindex)
			match id:
				0 : _add_normal_node(SuntomeParaNode.normal_key())
				1 : _add_normal_node(SuntomeCountCheckNode.normal_key())
				2 : _add_normal_node(SuntomeTimeBeginNode.normal_key())
				3 : _add_normal_node(SuntomeTimeCheckNode.normal_key())
				_ : Utility.CriticalFail("un implement selection")
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

	#实现复制贴贴
	state_panel.req_copy_data_cb = func(list) : _cliped_data = _copy_node(list)
	state_panel.req_paste_data_cb = func() : _paste_node(_cliped_data)

	#节点播放调试控制内容
	%bt_start_begin.pressed.connect(func():
		#清空变量等信息
		SuntomeGlobal.clear_property()
		SuntomePlayer.start_from_node(SuntomeGlobal.begin_node)
		pass
	)

	%bt_step.pressed.connect(func():
		SuntomePlayer.step_in_next()
	)

	SuntomePlayer.suntome_node_change.connect(_process_suntome_node_played)
	pass # Replace with function body.


func _fresh_panel_from_global():
	var uid_to_node = _create_state_node_in_list(SuntomeGlobal.suntome_nodes.values())

	#处理start和sourou
	for left_node in init_nodes():
		var stmnode = get_node_SuntomeNode(left_node)
		for right_uid in stmnode.nextNodes.keys():
			var right_node = uid_to_node[right_uid]
			state_panel.connect_node(left_node, right_node)
		pass

	# #更新连接的标签信息
	# for node : StateNode in uid_to_node.values():
	# 	_update_node_line_index_info(node)

	for node : StateNode in init_nodes():
		_update_node_line_index_info(node)
	pass


#基于SuntomeNodeBase对象列表，在editor中创建节点，其中std_nodes的成员对象为SuntomeNodeBase派生对象
#返回值为构造的uid到StateNode映射{uid : StateNode}
func _create_state_node_in_list(std_nodes : Array) -> Dictionary:
	var uid_to_node := Dictionary() #存储uid到StateNode的临时映射对象

	#构造节点
	for stmnode : SuntomeNodeBase in std_nodes:
		var node = state_panel.new_node()
		node.position = stmnode.position
		uid_to_node.set(stmnode.uid, node)

		if stmnode is SuntomeNode:
			SuntomContent.Create(node, stmnode, Callable(self, "_update_node_line_index_info"))
			if stmnode.is_transit_node:
				_change_node_to_trans(node)
		elif stmnode is SuntomeSelectPictNode:
			SuntomeSPicContent.create_ctt_from_pic_node(node, stmnode,
				Callable(self, "_update_node_line_index_info"),
				Callable(self, "_select_pic_ctt_line_delete_req")
			)
		elif stmnode.has_method("normal_key"):
			var _key = stmnode.normal_key()
			NormalNodeFuncMap[_key][1].create_ctt_from_node(node, stmnode)
		# for TTYPE in NormalNodeFuncMap:
		# 	# if stmnode is TTYPE:
		# 	NormalNodeFuncMap[TTYPE].create_ctt_from_node(node, stmnode)
		# 	continue

		# elif stmnode is SuntomeParaNode:
		# 	SuntomeParaNodePanel.create_ctt_from_node(node,stmnode)
		# elif stmnode is SuntomeCountCheckNode:
		# 	SuntomeCountCheckNodePanel.create_ctt_from_node(node, stmnode)
		else:
			push_error("stmnode type error")
			Utility.CriticalFail()


	var deftercall = func():
		for node in uid_to_node.values():
			node.position = get_node_SuntomeNode(node).position
	deftercall.call_deferred()

	#其次连接所有的节点
	for stmnode : SuntomeNodeBase in std_nodes:
		var left_node = uid_to_node[stmnode.uid]
		for right_uid in stmnode.nextNodes.keys():
			var right_node = uid_to_node[right_uid]
			state_panel.connect_node(left_node, right_node)

	#更新连接的标签信息
	for node : StateNode in uid_to_node.values():
		_update_node_line_index_info(node)

	return uid_to_node


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


# func _add_setting_node() -> StateNode:
# 	var next = state_panel.new_node()
# 	next.position = state_panel.pos_map(state_panel.size / 2)
# 	var newNode := SuntomeParaNode.new_node()
# 	newNode.position = next.position
# 	SuntomeGlobal.suntome_nodes.set(newNode.uid, newNode)
# 	var _content = SuntomeParaNodePanel.create_ctt_from_node(next, newNode)
# 	return next


# func _add_count_check_node() -> StateNode:
# 	var next = state_panel.new_node()
# 	next.position = state_panel.pos_map(state_panel.size / 2)
# 	var newNode := SuntomeCountCheckNode.new_node()
# 	newNode.position = next.position
# 	SuntomeGlobal.suntome_nodes.set(newNode.uid, newNode)
# 	var _content = SuntomeCountCheckNodePanel.create_ctt_from_node(next, newNode)
# 	return next


func _add_normal_node(key : String) -> StateNode:
	var pair = NormalNodeFuncMap[key]
	var next = state_panel.new_node()
	next.position = state_panel.pos_map(state_panel.size / 2)
	var newNode = pair[0].new_node()
	newNode.position = next.position
	SuntomeGlobal.suntome_nodes.set(newNode.uid, newNode)
	var _content = pair[1].create_ctt_from_node(next, newNode)
	return next


func _change_node_to_trans(node : StateNode):
	var ctt = node.get_ctt()
	if ctt is SuntomContent:
		ctt.ref_suntome_node.is_transit_node = true
		node.get_container().remove_child(ctt)
		node.custom_data = ctt
		var lab = Label.new()
		lab.text = tr("Port")
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
	if null == node:
		%param_container.hide()
		return

	var ctt = get_node_ctt(node)
	%param_container.show()
	ctt.show_node_param(%param_container)
	pass


#用户选中的节点发生变化信号槽函数
func _node_select_change(selected_node : StateNode):
	_cur_select_node = selected_node
	_show_node_param(selected_node)
	pass


func _context_menu_show(emit_node : StateNode, local_pos : Vector2):
	#构造菜单选项
	var context_menu_items := Array()

	if null == emit_node:
		var change_position = func(nd : StateNode, pos_new : Vector2):
			var stmnode := get_node_SuntomeNode(nd)
			stmnode.position = pos_new
			nd.position = pos_new

		context_menu_items.append(CusContentMenu.bt(tr("Add Play Node"), func():
			var nd = _add_state_node()
			change_position.call(nd, state_panel.pos_map(local_pos))
		))

		context_menu_items.append(CusContentMenu.bt(tr("Add Port Node"), func():
			var nd = _add_trans_node()
			change_position.call(nd, state_panel.pos_map(local_pos))
		))

		for pair in [
				[tr("Add Setting Node") , SuntomeParaNode.normal_key()],
				[tr("Add Check Count Node") , SuntomeCountCheckNode.normal_key()],
				[tr("Add Time Begin Node") , SuntomeTimeBeginNode.normal_key()],
				[tr("Add Check Time Node") , SuntomeTimeCheckNode.normal_key()],
			]:
			var name_ = pair[0]
			var type_key = pair[1]
			context_menu_items.append(CusContentMenu.bt(name_, func():
				var nd = _add_normal_node(type_key)
				change_position.call(nd, state_panel.pos_map(local_pos))
			))
			pass

		if not _cliped_data.is_empty():
			context_menu_items.append(CusContentMenu.bt(tr("paste"), func():
				_paste_node(_cliped_data)
			))
		pass
	else:
		context_menu_items.append(CusContentMenu.bt(tr("play from this node"), func():
			var node = get_node_SuntomeNode(emit_node)
			SuntomePlayer.start_from_node(node)
			pass
		))

		if emit_node not in init_nodes():
			var node = get_node_SuntomeNode(emit_node)
			if node is SuntomeNode:
				if node.is_transit_node:
					context_menu_items.append(CusContentMenu.bt(tr("change type to play node"), func():
						_change_node_to_content(emit_node)
					))
				else:
					context_menu_items.append(CusContentMenu.bt(tr("change type to port node"), func():
						_change_node_to_trans(emit_node)
					))
				pass

			context_menu_items.append(CusContentMenu.bt(tr("copy"), func():
				var now_selected_nodes = state_panel.now_selected_nodes()
				if emit_node in now_selected_nodes:
					_cliped_data = _copy_node(now_selected_nodes)
				else:
					_cliped_data = _copy_node([emit_node])
					state_panel.unselect_all()
					state_panel.add_selected([emit_node])
				pass
			))

			context_menu_items.append(CusContentMenu.bt(tr("delete node"), func():
				var now_selected_nodes = state_panel.now_selected_nodes()
				if emit_node in now_selected_nodes:
					for node_ in now_selected_nodes:
						state_panel.node_require_delete(node_)
				else:
					state_panel.node_require_delete(emit_node)
					state_panel.unselect_all()

				%param_container.hide()
				pass
			))

	#显示右键菜单
	CusContentMenu.create(self, get_global_mouse_position(), context_menu_items)
	print("context menu show")
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


#将需要拷贝的对象序列化并返回
func _copy_node(list : Array) -> String:
	var stmnodes := Dictionary() #流程节点对象

	for nd : StateNode in list:
		if nd in init_nodes(): #默认节点不复制
			continue

		var stmnd = get_node_SuntomeNode(nd)
		stmnodes.set(stmnd.uid, SuntomeSerialization.SuntomeNodeSerialize(stmnd))

	return JSON.stringify(JSON.from_native(stmnodes))


#将基于_copy_node获取的数据进行反序列化，并拷贝到鼠标所在的地方
func _paste_node(data : String):
	if data.is_empty():
		return

	var json = JSON.new()
	var error = json.parse(data)
	if OK != error:
		return "JSON 解析错误：" + json.get_error_message() + " 行号 "+ String.num_int64(json.get_error_line())
	var stmnodes = JSON.to_native(json.data)
	var orguidlist = stmnodes.keys()
	var exist_uids = SuntomeGlobal.suntome_nodes.keys()

	if stmnodes.is_empty():
		return

	#构造原始uid到新uid的映射
	var uidmapdict := Dictionary()
	for _uid : int in orguidlist:
		var new_uid = Utility.make_uniq_uid(exist_uids)
		uidmapdict.set(_uid, new_uid)
		exist_uids.append(new_uid)

	var new_stmnodes := Dictionary()

	var mapcbs := SuntomeSerialization.GlobalInfoMapCBs.new()
	mapcbs.sound_obj_map_cb = func(key : String): return SuntomeGlobal.sound_object_contents.get(key)
	mapcbs.select_pic_map_cb = func(key : String): return SuntomeGlobal.select_pic_contents.get(key)
	mapcbs.suntomenode_map_cb = func(_uid : int): return new_stmnodes.get(_uid)
	mapcbs.uid_map_cb = func(_uid : int): return uidmapdict.get(_uid)

	#执行反序列化
	print("开始执行拷贝")
	var errorinfo := Array()
	for uid in stmnodes:
		print(uid)
		var dict : Dictionary = stmnodes[uid]
		var stmnode := SuntomeSerialization.SuntomeUnSerializeFisrt(dict, errorinfo, mapcbs)
		if not errorinfo.is_empty():
			push_error(errorinfo)
			return "error in paste suntome_nodes unserialize step1"

		var preuid = stmnode.uid
		stmnode.uid = uidmapdict.get(preuid)
		# SuntomeGlobal.suntome_nodes.set(stmnode.uid, stmnode)
		new_stmnodes.set(stmnode.uid, stmnode)

	for uid in stmnodes:
		var dict : Dictionary = stmnodes[uid]
		var node_data = dict["data"]
		var true_uid = uidmapdict.get(uid)
		var errorlist = new_stmnodes[true_uid].unserialize_second(node_data, mapcbs)
		if not errorlist.is_empty():
			push_error(errorlist)
			# return "error in node connect: " + String.num_int64(uid)
	#执行结束

	#对节点坐标进行偏移，适配鼠标位置
	#获取鼠标的坐标
	var mouse_pos = state_panel.get_local_mouse_position()
	var panel_pos = state_panel.pos_map(mouse_pos)

	#获取复制节点的平均坐标
	var avgpos := Vector2.ZERO
	for stnd : SuntomeNodeBase in new_stmnodes.values():
		avgpos += stnd.position
	avgpos = avgpos / new_stmnodes.size()
	#计算偏移
	var diff_pos = panel_pos - avgpos
	#将偏移应用到每一个节点上
	for stnd : SuntomeNodeBase in new_stmnodes.values():
		stnd.position += diff_pos

	#将新的节点添加到global和editor中
	SuntomeGlobal.suntome_nodes.merge(new_stmnodes)

	#将新的节点显示在编辑界面中
	var uid_to_statenode = _create_state_node_in_list(new_stmnodes.values())

	#选中复制出来的节点
	state_panel.unselect_all()
	state_panel.add_selected(uid_to_statenode.values())
	pass


func _process_suntome_node_played(stm_node : SuntomeNodeBase):
	#找到stm_node对应的StateNode
	var temp = []
	state_panel.each_node(func(nd : StateNode):
		if stm_node == get_node_SuntomeNode(nd):
			temp.append(nd)
			return false
		return true
	)

	if temp.is_empty():
		return

	var stnode : StateNode = temp[0]

	if _preplayed_node:
		if stm_node != _preplayed_node:
			_preplayed_node.fade()

	if stnode:
		_preplayed_node = stnode
		_preplayed_node.show_back_rect()
		pass
	pass
