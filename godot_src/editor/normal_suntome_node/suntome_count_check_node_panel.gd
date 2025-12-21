class_name SuntomeCountCheckNodePanel extends VBoxContainer

var _ref_node : SuntomeCountCheckNode = null

static func create_from_check_node(node : SuntomeCountCheckNode) -> SuntomeCountCheckNodePanel:
	var ctrl : SuntomeCountCheckNodePanel= preload("res://editor/normal_suntome_node/suntome_count_check_node_panel.tscn").instantiate()
	ctrl._ref_node = node
	ctrl._set_count(node.pass_count)
	return ctrl


static func create_ctt_from_node(
		parent : StateNode,
		node : SuntomeCountCheckNode
		) -> SuntomeContainerContent:
	if null == node:
		return

	var ctt := SuntomeContainerContent.create_ctt_from_state_and_node(parent, node)

	var panel : SuntomeCountCheckNodePanel = create_from_check_node(node)
	panel._ref_node = node
	ctt.connect_contained(panel)
	return ctt


func _ready() -> void:
	%count.value_changed.connect(func(value : float):
		if _ref_node:
			_ref_node.pass_count = floor(value)
	)
	pass


func _set_count(c : int):
	%count.value = c


#和SuntomeContainerContent关联的函数
func node_text() -> String:
	return tr("Suntome Count Check", "node_name")



#和PlayNodeEditor联动的函数
#返回用户拖动节点连线时显示的线条信息
func get_drag_line_info() -> String:
	if _ref_node.nextNodes.size() >= 2:
		return tr("not allowed")

	if _ref_node.nextNodes.has(_ref_node.success_node_uid):
		return tr("reject route")

	return tr("passed route")


#当连线连接时，判断是否可以连接
func line_connect_check() -> bool:
	if _ref_node.nextNodes.size() < 2:
		return true
	return false


#处理和target相连的逻辑，仅当line_connect_check()返回true时才会执行该函数
func process_node_connect(target : SuntomeNodeBase):
	_ref_node.nextNodes.set(target.uid, target)
	if not _ref_node.nextNodes.has(_ref_node.success_node_uid):
		_ref_node.success_node_uid = target.uid


#处理和target断开连接的逻辑
func process_node_disconnect(target : SuntomeNodeBase):
	_ref_node.nextNodes.erase(target.uid)
	if target.uid == _ref_node.success_node_uid:
		_ref_node.success_node_uid = -1


#获取该节点和其他节点的连线文本信息，该函数返回一个可调用的函数对象(other_node : SuntomeNodeBase) -> String
func get_connect_line_lable() -> Callable:
	return func(_other_node : SuntomeNodeBase) -> String:
		if _other_node.uid == _ref_node.success_node_uid:
			return tr("passed route")
		return tr("reject route")
