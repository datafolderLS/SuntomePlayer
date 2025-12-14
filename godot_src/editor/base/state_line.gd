extends Control

class_name StateLine

#用户请求删除线条时触发该信号，emit是请求删除的线条
signal line_require_delete(emit : StateLine)

@onready var line : Line2D = get_node("rot_root/move_root/Line2D")
@onready var arrow : Polygon2D = get_node("rot_root/move_root/Polygon2D")
@onready var detect : Panel = get_node("rot_root/move_root/mouse_detect")

#标记当前线段是否是节点到节点模式
var isNodeToNode = false
var begin : StateNode = null
var end = null

#连接时线段和node的距离
const linemargin = 5
#StateNode边缘圆角半径
const noderadius = 20

#旋转轴
@onready var rotRoot : Control = get_node("rot_root")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	detect.mouse_entered.connect(_mouse_enter)
	detect.mouse_exited.connect(_mouse_out)
	detect.gui_input.connect(_mouse_detect_input)
	pass # Replace with function body.


func is_connected_from_node_to_node(from : StateNode, to : StateNode) -> bool:
	if not isNodeToNode:
		return false
	return begin == from and end == to


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if null == end:
		return

	var lpos = begin.position
	var lsize = begin.size
	lpos = lpos + lsize / 2

	if isNodeToNode :
		var rpos = end.position
		var rsize = end.size
		rpos = rpos + rsize / 2
		var para = _calc_node_to_node_true_position(lpos, lsize, rpos, rsize)
		_update_pos(para[0], para[1])
		pass
	else:
		var rpos = end.call()
		var rsize = Vector2(0,0)
		var para = _calc_node_to_node_true_position(lpos, lsize, rpos, rsize)
		_update_pos(para[0], para[1])
		pass

	pass


#让线段在from指向的StateNode连向to的StateNode
func connect_from_node_to_node(from : StateNode, to : StateNode) -> void:
	isNodeToNode = true
	begin = from
	end = to
	pass


#设置线条宽度
func set_line_width(width : float) -> void:
	line.width = width
	pass


#让线条连接stateNode和to函数返回的坐标
func connect_from_node_to_point(from : StateNode, to : Callable) -> void:
	isNodeToNode = false
	begin = from
	end = to
	pass


func _calc_node_to_node_true_position(lpos : Vector2, lsize : Vector2, rpos : Vector2, rsize : Vector2) -> Array:
	var dir = (rpos - lpos)

	var lsizehalf = lsize / 2
	var rsizehalf = rsize / 2

	var start = lpos + Vector2(sign(dir.x) * lsizehalf.x, sign(dir.y) * lsizehalf.y)
	var endp = rpos - Vector2(sign(dir.x) * rsizehalf.x, sign(dir.y) * rsizehalf.y)

	if abs(dir.x) < (lsizehalf.x + rsizehalf.x) :
		var temp = abs(rpos.x - lpos.x) - lsizehalf.x - rsizehalf.x
		var temp2 = -abs(lsizehalf.x + rsizehalf.x) / lsizehalf.x
		var xdiffl = temp / temp2
		var xdiffr = xdiffl * rsizehalf.x / lsizehalf.x

		start.x = start.x - sign(dir.x) * xdiffl
		endp.x = endp.x + sign(dir.x) * xdiffr
		pass
	elif abs(dir.y) < (lsizehalf.y + rsizehalf.y) :
		var temp = abs(rpos.y - lpos.y) - lsizehalf.y - rsizehalf.y
		var temp2 = -abs(lsizehalf.y + rsizehalf.y) / lsizehalf.y
		var ydiffl = temp / temp2
		var ydiffr = ydiffl * rsizehalf.y / lsizehalf.y

		start.y = start.y - sign(dir.y) * ydiffl
		endp.y = endp.y + sign(dir.y) * ydiffr
		pass

	return [start, endp]
	#pass


func _update_pos(from : Vector2, to : Vector2) -> void:
	position = from
	var dir = to - from
	var lenth = dir.length()
	line.set_point_position(1, Vector2(lenth - 10, 0))
	detect.size.x = lenth - 10
	arrow.position = Vector2(lenth - 20, 0)
	rotRoot.rotation = dir.angle()
	%Label.position = Vector2(lenth * 0.25 - 11.0, -25)
	%Label.rotation = -from.angle_to_point(to)
	pass


func _mouse_enter():
	#print("line mouse enter")
	set_line_width(5)
	pass

func _mouse_out():
	set_line_width(3)
	#print("line mouse leave")
	pass


#修改文字信息
func set_label(text : String):
	%Label.text = text


#检测用户右键点击的槽函数
func _mouse_detect_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if MOUSE_BUTTON_LEFT != event.button_index:
			return

		if event.pressed and Input.is_key_pressed(KEY_ALT):
			line_require_delete.emit(self)
			return
	pass
