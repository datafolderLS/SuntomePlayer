extends PanelContainer

#StateNode是用于模仿GraphNode和UE中的动画状态机节点而设计的StatePanel子成员控件，主要用于响应玩家的拖拽、点击事件
class_name StateNode

#容器，用于放入自定义的控件
@onready var container : BoxContainer = get_node("%container")
@onready var back : PanelContainer = get_node("%backContainer")

#用户自定义数据，用于存储用户的自定义信息
var custom_data = null

#当节点被点击时触发信号
# signal content_clicked(emit_node : StateNode, clicked_pos : Vector2)
#节点被右键点击时触发信号
signal context_menu_req(emit_node : StateNode, clicked_pos : Vector2)

#当用户点击边框时信号触发，传递对象为触发信号的statenode和鼠标点击的位置
signal margin_click_start(emit_node : StateNode, clicked_pos : Vector2)
signal margin_click_end(emit_node : StateNode, clicked_pos : Vector2)
# signal node_require_delete(emit_node : StateNode)
signal node_pos_updated(emit_node : StateNode, pos : Vector2)


var rect_idle_style : StyleBox = preload("res://editor/base/state_panel_style/rect_idle.tres")
var rect_active_style : StyleBox = preload("res://editor/base/state_panel_style/rect_active.tres")
var border_seleted_style : StyleBox = preload("res://editor/base/state_panel_style/border_selected.tres")
var border_unseleted_style : StyleBox = preload("res://editor/base/state_panel_style/border_unselected.tres")

#鼠标按下时鼠标和node坐标的偏移值
var diffPos : Vector2 = Vector2(0,0)
var doDrag : bool = false #是否在被拖动
var _begin_drag_pos : Vector2 = Vector2.ZERO

var last_press_time : float = 0.0

#该node所在的StatePanel对象，由StatePanel内部函数赋值
var _panel : StatePanel = null

#为框选准备的回调函数
var content_input_cb : Callable = Callable()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	back.gui_input.connect(rect_input)
	get_node("%PanelContainer").gui_input.connect(content_input)

	back.mouse_exited.connect(rect_mouse_exited)
	back.mouse_entered.connect(rect_mouse_enter)

	pass # Replace with function body.


#返回存储内容控件的容器，用于调用者对内容进行自定义
func get_container() -> BoxContainer:
	return container


func rect_mouse_exited():
	back.add_theme_stylebox_override("panel", rect_idle_style)
	pass

func rect_mouse_enter():
	back.add_theme_stylebox_override("panel", rect_active_style)
	pass

#边框被按下的槽函数
func rect_input(event: InputEvent) -> void:
	#print(event)
	if not event is InputEventMouseButton:
		return

	#鼠标事件，高亮区域

	if MOUSE_BUTTON_LEFT != event.button_index:
		return

	if event.pressed:
		margin_click_start.emit(self, get_parent().get_local_mouse_position())
	else:
		margin_click_end.emit(self, get_parent().get_local_mouse_position())
	pass


#内容被按下的槽函数
func content_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			# MOUSE_BUTTON_LEFT:
			# 	#用户请求删除节点
			# 	if Input.is_key_pressed(KEY_ALT) and event.pressed:
			# 		node_require_delete.emit(self)
			# 		return

			# 	#用户点击（鼠标按下弹起）事件检测
			# 	if event.pressed:
			# 		last_press_time = Time.get_ticks_msec()
			# 	else:
			# 		if Time.get_ticks_msec() - last_press_time < 500.0:
			# 			content_clicked.emit(self, get_parent().get_local_mouse_position())

			# 	doDrag = event.pressed
			# 	var localPos = get_parent().get_local_mouse_position()
			# 	diffPos = position - localPos
			# 	pass
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					last_press_time = Time.get_ticks_msec()
				else:
					if Time.get_ticks_msec() - last_press_time < 500.0:
						context_menu_req.emit(self, get_parent().get_local_mouse_position())
				pass
		pass

	# elif event is InputEventMouseMotion:
	# 	if doDrag:
	# 		var localPos = get_parent().get_local_mouse_position()
	# 		var requiPos = localPos + diffPos
	# 		position = requiPos
	# 		node_pos_updated.emit(self, position)
	# 	pass
	content_input_cb.call(self, event)
	pass


func start_drag():
	doDrag = true
	_begin_drag_pos = position
	# content_clicked.emit(self, get_parent().get_local_mouse_position())
	pass


func update_mouse_diff(diff_pos : Vector2):
	if doDrag:
		position = _begin_drag_pos + diff_pos
		node_pos_updated.emit(self, position)
	pass


func end_drag():
	doDrag = false
	pass


#设置选中状态
func set_selected(seletecd : bool):
	if seletecd:
		add_theme_stylebox_override("panel", border_seleted_style)
	else:
		add_theme_stylebox_override("panel", border_unseleted_style)
	pass


func get_ctt():
	return get_container().get_child(0)


func get_panel() -> StatePanel:
	return _panel
