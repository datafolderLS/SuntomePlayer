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
signal node_selected(selected_node : StateNode, pre_selected : StateNode)
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

const scale_rate_list = [1, 0.75, 0.5, 0.25, 0.1]
var current_scale_index = 0

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
var _cur_selected_node : StateNode = null

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
	node.node_require_delete.connect(node_require_delete)
	node.content_clicked.connect(_node_content_clicked)
	node.context_menu_req.connect(
		func(emit_node : StateNode, clicked_pos : Vector2):
			context_menu_req.emit(emit_node, get_local_mouse_position())
	)
	node.node_pos_updated.connect(
		func(emit_node : StateNode, pos : Vector2) : node_pos_updated.emit(emit_node, pos)
	)
	node._panel = self
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
#bug 这里进行了按键alt按下的检测，产生的效果是全局的，如果在其他地方发现鼠标不能设置的话，就要考虑这里了
#这里先偷懒这么写了
func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return

	if Input.is_key_pressed(KEY_ALT) and Rect2(Vector2(0,0), size).has_point(get_local_mouse_position()):
		Input.set_custom_mouse_cursor(preload("res://editor/icon/delete_16.png"), Input.CURSOR_ARROW, Vector2(8,8))
		#mouse_default_cursor_shape = Control.CURSOR_CROSS
		#Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	else:
		Input.set_custom_mouse_cursor(null)
	pass


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton :
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				doDrag = event.pressed
				drag_diff_pos = root_container.position - get_local_mouse_position()
			MOUSE_BUTTON_WHEEL_UP:
				_scale_in_local_pos(get_local_mouse_position(), -1)
				pass
			MOUSE_BUTTON_WHEEL_DOWN:
				_scale_in_local_pos(get_local_mouse_position(), 1)
				pass

	elif event is InputEventMouseMotion:
		if doDrag:
			var new_pos = get_local_mouse_position() + drag_diff_pos
			root_container.position = new_pos
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

			if node == _cur_selected_node:
				_cur_selected_node = null
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
func _node_content_clicked(emit_node : StateNode, clicked_pos : Vector2):
	if emit_node == _cur_selected_node:
		return

	if null != _cur_selected_node:
		_cur_selected_node.set_selected(false)

	emit_node.set_selected(true)

	var temp = _cur_selected_node
	_cur_selected_node = emit_node

	node_selected.emit(emit_node, temp)
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
