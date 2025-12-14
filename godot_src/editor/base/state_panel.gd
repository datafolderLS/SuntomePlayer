extends Control

#用于存放和组织StateNode的面板
class_name StatePanel

#用户触发信号，当用户在面板上连接了一个新的StateLine时，信号触发，并将该连接的开头结尾传递
signal node_connected(from : StateNode, to : StateNode)
#用户触发信号，当用户在面板上删除了一个已有的StateLine连接时，信号触发，并将该连接原来的开头结尾传递
signal node_disconnected(from : StateNode, to : StateNode)
#用户触发信号，当用户在面板上删除一个已有的node时，信号触发
signal node_deleted(node : StateNode)
#用户触发信号，当node被选中时，触发该信号，pre_selected可能为null
signal node_selected(selected_node : StateNode)
#用户在节点上点击请求右键菜单
signal context_menu_req(emit_node : StateNode, pos : Vector2)
#节点被用户拖动坐标更新的信号
signal node_pos_updated(emit_node : StateNode, pos : Vector2)

#所有state_node的父级
@onready var root_container : Control = get_node("Panel/panelContainer")
@onready var line_container : Control = get_node("Panel/panelContainer/LineContainer")
@onready var node_container : Control = get_node("Panel/panelContainer/nodeContainer")

var doDrag : bool = false #标记是否正在进行拖动的标志位
var drag_diff_pos : Vector2 = Vector2(0,0) #标记是否正在进行拖动的标志位

const scale_rate_list = [1.5, 1.15, 1, 0.9, 0.81, 0.729, 0.656, 0.59, 0.53, 0.43, 0.34, 0.28, 0.18, 0.1]
var current_scale_index = 2

#用户拖线时创建的StateLine
var player_line : StateLine = null

#存储外部传递的函数对象，用来判断用户的删除操作是否采纳
var node_delete_check_func : Callable    #函数为(StateNode)->bool
var line_delete_check_func : Callable    #函数为(StateLine)->bool
var line_connect_check_func : Callable    #函数为(StateNode, StateNode)->bool

#当用户拖拽线时请求获取临时文字的函数，参数为(emit_node : StateNode)->String
var req_line_drag_label_text_func : Callable


#拖拽回调函数，当用户拖拽数据到面板时，触发该回调
var drop_in_panel_availiable_func : Callable #传参和_can_drop_data一致，要求返回bool
var drop_in_panel_cb : Callable #传参和_drop_data一致

#记录当前被选中的node
# var _cur_selected_node : StateNode = null

#记录节点拖动的鼠标开始位置
var _node_begin_drag_mouse_pos : Vector2 = Vector2.ZERO
#记录是否正在框选的标志变量
var _is_multi_select : bool = false
#记录框选的开始位置
var _multi_select_mouse_start_pos : Vector2 = Vector2.ZERO
#记录多选的信息，使用Dictionary存储，键为选择的nodes，内容为{state_node, any_number}
var _multi_selected_nodes : = Dictionary()
#本地拷贝数据存储，该数据由外部进行设置
var _cliped_data := String()
#请求复制回调，由该面板的使用者进行设置，(Array[StateNode])->String, 返回String并赋值给_cliped_data对象
var req_copy_data_cb := Callable()
#请求拷贝回调，由该面板的使用者进行设置，(String)->void，其中String是_cliped_data对象
var req_paste_data_cb := Callable()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Input.set_custom_mouse_cursor(preload("res://editor/icon/delete_16.png"), Input.CURSOR_CROSS, Vector2(8,8))
	#get_node("StatePanelDeleteHint").set_func(
		#func()->Vector2:
			#return get_local_mouse_position()
	#)
	pass # Replace with function body.


#在内部创建一个StateNode
func new_node() -> StateNode:
	var node = preload("res://editor/base/state_node.tscn").instantiate()
	node.set_deferred("size", Vector2(60,60))
	node.position = Vector2(20,20)
	node.set_anchors_preset(Control.PRESET_TOP_LEFT)
	node_container.add_child(node)
	node.margin_click_start.connect(_start_draw_player_line)
	node.margin_click_end.connect(_end_draw_player_line)
	# node.node_require_delete.connect(node_require_delete)
	# node.content_clicked.connect(
	# 	func(emit_node : StateNode, clicked_pos : Vector2):
	# 		_multi_selected_nodes.set(emit_node, null)
	# 		_node_content_clicked(emit_node, clicked_pos)
	# )
	node.context_menu_req.connect(
		func(emit_node : StateNode, _clicked_pos : Vector2):
			context_menu_req.emit(emit_node, get_local_mouse_position())
	)
	node.node_pos_updated.connect(
		func(emit_node : StateNode, pos : Vector2) : node_pos_updated.emit(emit_node, pos)
	)
	node._panel = self

	node.content_input_cb = Callable(self, "_state_node_content_input")
	return node


#创建一个line到line_container里
func new_line() -> StateLine:
	var line = preload("res://editor/base/state_line.tscn").instantiate()
	line_container.add_child(line)
	line.line_require_delete.connect(line_require_delete)
	return line


#将两个StateNode相连，方向是from到to
func connect_node(from : StateNode, to : StateNode) -> void:
	#首先创建一state_line，然后将state_line置于line_container下
	var line = new_line()
	line.connect_from_node_to_node(from, to)
	pass


func is_nodes_has_connected(from : StateNode, to : StateNode) -> bool:
	var lines = line_container.get_children()
	for l in lines:
		if l.is_connected_from_node_to_node(from, to):
			return true
	return false


#清空from节点出来的连线
func clear_connect(from : StateNode):
	var lines = line_container.get_children()
	var need_delete : Array = Array()
	for l : StateLine in lines:
		if from == l.begin and l.isNodeToNode:
			need_delete.append(l)

	for l in need_delete:
		_remove_line(l)


#取消所有选择
func unselect_all():
	_clear_multi_selected()


#将以下节点加入选择列表
func add_selected(list : Array):
	_select_nodes(list)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#bug 这里进行了按键alt按下的检测，产生的效果是全局的，如果在其他地方发现鼠标不能设置的话，就要考虑这里了
#这里先偷懒这么写了
func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	var has_mouse_in_rect = Rect2(Vector2(0,0), size).has_point(get_local_mouse_position())

	if Input.is_key_pressed(KEY_ALT) and has_mouse_in_rect:
		Input.set_custom_mouse_cursor(preload("res://editor/icon/delete_16.png"), Input.CURSOR_ARROW, Vector2(8,8))
		#mouse_default_cursor_shape = Control.CURSOR_CROSS
		#Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	else:
		Input.set_custom_mouse_cursor(null)

	if false == doDrag:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) and has_mouse_in_rect:
			doDrag = true
			drag_diff_pos = root_container.position - get_local_mouse_position()


	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		doDrag = false

	if doDrag:
		var new_pos = get_local_mouse_position() + drag_diff_pos
		root_container.position = new_pos
		_clamp_cam_pos()
	pass


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not Rect2(Vector2(0,0), size).has_point(get_local_mouse_position()):
		return

	if event is InputEventKey:
		# print(event.ctrl_pressed)
		if not event.echo:
			if KEY_C == event.keycode and event.is_pressed() and event.ctrl_pressed:
				#执行复制
				_copy_multi_select_in_clipdata()
				pass
			elif KEY_V == event.keycode and event.is_pressed() and event.ctrl_pressed:
				#执行复制
				_paste_multi_select_in_clipdata()
				pass
	pass


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton :
		match event.button_index:
			# MOUSE_BUTTON_MIDDLE:
			# 	doDrag = event.pressed
			# 	drag_diff_pos = root_container.position - get_local_mouse_position()
			MOUSE_BUTTON_WHEEL_UP:
				if not doDrag:
					_scale_in_local_pos(get_local_mouse_position(), -1)
					_clamp_cam_pos()
				pass
			MOUSE_BUTTON_WHEEL_DOWN:
				if not doDrag:
					_scale_in_local_pos(get_local_mouse_position(), 1)
					_clamp_cam_pos()
				pass
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_node_content_clicked(null, node_container.get_local_mouse_position())
					# _clear_multi_selected()
					_multi_select_mouse_start_pos = %Panel.get_local_mouse_position()
					%select_panel.position = _multi_select_mouse_start_pos
					%select_panel.size = Vector2.ZERO
				elif _is_multi_select:
					var select_rect = %select_panel.get_rect()
					var begin = pos_map(select_rect.position)
					var end = pos_map(select_rect.end)
					_select_nodes_in_rect(Rect2(begin, end - begin))
					pass

				_is_multi_select = event.pressed
				%select_panel.visible = event.pressed

	elif event is InputEventMouseMotion:
		if _is_multi_select:
			var new_mouse_pos = %Panel.get_local_mouse_position()
			var rect = Utility.make_rect2(new_mouse_pos, _multi_select_mouse_start_pos)
			%select_panel.position = rect.position
			%select_panel.size = rect.size
	pass


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not Rect2(Vector2(0,0), size).has_point(get_local_mouse_position()):
		return

	#这里主要是处理子节点上的中间信息
	if event is InputEventMouseButton :
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				doDrag = event.pressed
				drag_diff_pos = root_container.position - get_local_mouse_position()
			MOUSE_BUTTON_WHEEL_UP:
				if not doDrag:
					_scale_in_local_pos(get_local_mouse_position(), -1)
					_clamp_cam_pos()
				pass
			MOUSE_BUTTON_WHEEL_DOWN:
				if not doDrag:
					_scale_in_local_pos(get_local_mouse_position(), 1)
					_clamp_cam_pos()
				pass
	elif event is InputEventMouseMotion:
		if doDrag:
			var new_pos = get_local_mouse_position() + drag_diff_pos
			root_container.position = new_pos
			_clamp_cam_pos()
	pass


#以pos为中心，对container的内容进行缩放，rate是增减的档位
func _scale_in_local_pos(pos : Vector2, rate : int):
	var newRate = current_scale_index + rate
	newRate = clampi(newRate, 0, scale_rate_list.size() - 1)

	if newRate == current_scale_index:
		return
	var preScalar = scale_rate_list[current_scale_index]
	var newScalar = scale_rate_list[newRate]
	current_scale_index = newRate

	var changeRate = newScalar / preScalar
	var dis = root_container.position - pos
	var newDis = dis * changeRate
	var newPos = newDis + pos
	root_container.position = newPos
	root_container.scale = Vector2(newScalar, newScalar)
	pass


#槽函数，绘制用户在面板上拖动连线的功能
func _start_draw_player_line(emit_node : StateNode, clicked_pos : Vector2):
	print(clicked_pos)
	player_line = new_line()
	player_line.connect_from_node_to_point(emit_node,
		func () -> Vector2:
			return root_container.get_local_mouse_position()
	)
	player_line.set_line_width(5)
	if req_line_drag_label_text_func.is_valid():
		var text : String = req_line_drag_label_text_func.call(emit_node)
		player_line.set_label(text)
	pass


func _end_draw_player_line(emit_node : StateNode, released_pos : Vector2):
	print(released_pos, "end")
	line_container.remove_child(player_line)
	player_line.queue_free()

	#判断是否有node在released_pos处
	#todo 这里先摆烂用遍历的方式，之后再优化
	var nodes = node_container.get_children()
	for n in nodes:
		if n == emit_node:
			continue
		if n.get_rect().has_point(released_pos):
			if not is_nodes_has_connected(emit_node, n):
				if line_connect_check_func.call(emit_node, n):
					print("connect node")
					connect_node(emit_node, n)
					node_connected.emit(emit_node, n)
			break
	pass


func _remove_line(line : StateLine):
	var from = line.begin
	var to = line.end
	line_container.remove_child(line)
	line.queue_free()
	node_disconnected.emit(from, to)


func disconnect_nodes(from : StateNode, to : StateNode):
	var lines = lines_from_node(from)
	for line : StateLine in lines:
		if to == line.end:
			_remove_line(line)
			break


func disconnect_line(line : StateLine):
	if null == line:
		return
	_remove_line(line)


func node_require_delete(node : StateNode):
	if node_delete_check_func.is_valid():
		if node_delete_check_func.call(node):
			#删除该节点，以及相连的StateLine
			#先删除StateLine，触发node_disconnected信号
			#再删除node，触发node_deleted信号

			#遍历所有的line对象
			var lines = line_container.get_children()
			for line in lines :
				if line.begin == node or line.end == node:
					_remove_line(line)
					pass

			#删除node
			node_deleted.emit(node)
			node_container.remove_child(node)
			node.queue_free()

			# if node == _cur_selected_node:
			# 	_cur_selected_node = null

			_multi_selected_nodes.erase(node)
			pass
	pass

func line_require_delete(line : StateLine):
	if line_delete_check_func.is_valid():
		if line_delete_check_func.call(line):
			#删除该连接
			_remove_line(line)
			pass
	pass


#槽函数，处理节点被点击的逻辑
func _node_content_clicked(emit_node : StateNode, _clicked_pos : Vector2):
	# if emit_node == _cur_selected_node:
	# 	return

	# if null != _cur_selected_node:
	# 	_cur_selected_node.set_selected(false)
	_clear_multi_selected()

	if null != emit_node:
		emit_node.set_selected(true)
		_multi_selected_nodes.set(emit_node, null)

	node_selected.emit(emit_node)
	pass


#拖拽相关函数
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not drop_in_panel_availiable_func.is_valid():
		return false

	return drop_in_panel_availiable_func.call(at_position, data)


func _drop_data(at_position: Vector2, data: Variant):
	if drop_in_panel_cb.is_valid():
		drop_in_panel_cb.call(at_position, data)
	pass


#将StatePanel的本地坐标映射到root_container的内部坐标中
func pos_map(panel_pos : Vector2) -> Vector2:
	var diff = panel_pos - root_container.position
	diff = diff / root_container.scale
	return diff


#获取由node发出的所有StateLine
func lines_from_node(node : StateNode) -> Array:
	var rel = Array()
	#遍历所有的line对象
	var lines = line_container.get_children()
	for line in lines :
		if line.begin == node:
			rel.append(line)

	return rel


#检查相机位置是否离内容太远，如果太远就限制位置
func _clamp_cam_pos():
	var nodes = node_container.get_children()
	if nodes.is_empty():
		return

	#获取内容的包容大小
	var rect_ = nodes.front().get_rect()
	for node_ in nodes:
		var nrect = node_.get_rect()
		rect_ = rect_.merge(nrect)

	var diff_pos = root_container.position
	var scalar = root_container.scale
	rect_.position = rect_.position * scalar + diff_pos
	rect_.size *= scalar

	var diff = Utility.calc_diff_rect_to_rect(rect_, Rect2(Vector2.ZERO, %Panel.size))
	root_container.position += diff
	pass


func _state_node_content_input(snode : StateNode, event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				#用户请求删除节点
				if Input.is_key_pressed(KEY_ALT) and event.pressed:
					# snode.node_require_delete.emit(snode)
					node_require_delete(snode)
					return

				#用户点击（鼠标按下弹起）事件检测
				if event.pressed:
					# snode.last_press_time = Time.get_ticks_msec()
					if not _multi_selected_nodes.has(snode):
						_node_content_clicked(snode, node_container.get_local_mouse_position())

					for nd in _multi_selected_nodes:
						nd.start_drag()
					_node_begin_drag_mouse_pos = node_container.get_local_mouse_position()
				else:
					for nd in _multi_selected_nodes:
						nd.end_drag()

					if _multi_selected_nodes.size() > 1:
						var pos_diff = node_container.get_local_mouse_position() - _node_begin_drag_mouse_pos
						if pos_diff.length() < 10.0:
							_node_content_clicked(snode, node_container.get_local_mouse_position())

				pass
			# MOUSE_BUTTON_RIGHT:
			# 	if event.pressed:
			# 		snode.last_press_time = Time.get_ticks_msec()
			# 	else:
			# 		if Time.get_ticks_msec() - snode.last_press_time < 500.0:
			# 			snode.context_menu_req.emit(snode, snode.get_parent().get_local_mouse_position())
				pass
		pass

	elif event is InputEventMouseMotion:
		var pos_diff = node_container.get_local_mouse_position() - _node_begin_drag_mouse_pos
		for nd in _multi_selected_nodes:
			nd.update_mouse_diff(pos_diff)
		# snode.update_mouse_diff(node_container.get_local_mouse_position() - _node_begin_drag_mouse_pos)
		# if snode.doDrag:
		# 	var localPos = snode.get_parent().get_local_mouse_position()
		# 	var requiPos = localPos + snode.diffPos
		# 	snode.position = requiPos
		# 	snode.node_pos_updated.emit(snode, snode.position)
		pass
	pass


func _select_nodes_in_rect(rect : Rect2):
	var nodes = node_container.get_children()

	# for nod : Control in nodes:
	# 	if rect.encloses(nod.get_rect()):
	# 		_multi_selected_nodes.set(nod, null)
	# 		nod.set_selected(true)

	# if _multi_selected_nodes.size() == 1:
	# 	_node_content_clicked(_multi_selected_nodes.keys().front(), node_container.get_local_mouse_position())

	var contained := nodes.filter(
		func(nod : Control):
			return rect.encloses(nod.get_rect())
	)

	_select_nodes(contained)
	pass


func _clear_multi_selected():
	for nod in _multi_selected_nodes:
		nod.set_selected(false)

	_multi_selected_nodes.clear()
	pass


func _copy_multi_select_in_clipdata():
	if req_copy_data_cb.is_valid():
		var value = req_copy_data_cb.call(_multi_selected_nodes.keys())
		if typeof(value) != TYPE_STRING:
			push_error("copy fail, not a valid string target")
			return
		_cliped_data = value
	pass


func _paste_multi_select_in_clipdata():
	if _cliped_data.is_empty():
		return

	if req_paste_data_cb.is_valid():
		req_paste_data_cb.call(_cliped_data)
	pass


#选中nodes里面的所有node，nodes对象成员为StateNode
func _select_nodes(nodes : Array):
	for nod : StateNode in nodes:
		_multi_selected_nodes.set(nod, null)
		nod.set_selected(true)

	if _multi_selected_nodes.size() == 1:
		_node_content_clicked(_multi_selected_nodes.keys().front(), node_container.get_local_mouse_position())
	pass
