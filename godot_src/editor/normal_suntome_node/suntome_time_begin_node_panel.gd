class_name SuntomeTimeBeginNodePanel extends VBoxContainer

var _ref_node : SuntomeTimeBeginNode = null


static func create_from_tbegin_node(node : SuntomeTimeBeginNode) -> SuntomeTimeBeginNodePanel:
	var ctrl : SuntomeTimeBeginNodePanel= preload("res://editor/normal_suntome_node/suntome_time_begin_node_panel.tscn").instantiate()
	ctrl._ref_node = node
	ctrl._set_text(node.time_tag)
	return ctrl

#通用接口
static func create_ctt_from_node(
		parent : StateNode,
		node : SuntomeTimeBeginNode
		) -> SuntomeContainerContent:
	if null == node:
		return

	var ctt := SuntomeContainerContent.create_ctt_from_state_and_node(parent, node)

	var panel : SuntomeTimeBeginNodePanel = create_from_tbegin_node(node)
	panel._ref_node = node
	ctt.connect_contained(panel)
	return ctt


func _ready() -> void:
	%tag.text_changed.connect(func(text : String):
		_ref_node.time_tag = text
		pass
	)
	pass


func _set_text(t : String):
	if t.is_empty():
		return
	%tag.text = t


#和SuntomeContainerContent关联的函数
func node_text() -> String:
	return "Suntome Time Begin"


#和PlayNodeEditor联动的函数
#返回用户拖动节点连线时显示的线条信息
func get_drag_line_info() -> String:
	if _ref_node.nextNodes.is_empty():
		return "after setting"
	return "not allowed"


#当连线连接时，判断是否可以连接
func line_connect_check() -> bool:
	if _ref_node.nextNodes.is_empty():
		return true
	return false


#处理和target相连的逻辑，仅当line_connect_check()返回true时才会执行该函数
func process_node_connect(target : SuntomeNodeBase):
	_ref_node.nextNodes.set(target.uid, target)


#处理和target断开连接的逻辑
func process_node_disconnect(target : SuntomeNodeBase):
	_ref_node.nextNodes.erase(target.uid)


#获取该节点和其他节点的连线文本信息，该函数返回一个可调用的函数对象(other_node : SuntomeNodeBase) -> String
func get_connect_line_lable() -> Callable:
	return func(_other_node : SuntomeNodeBase) -> String:
		return "after setting"
