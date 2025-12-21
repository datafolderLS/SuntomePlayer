class_name SuntomeTimeCheckNodePanel extends VBoxContainer

var _ref_node : SuntomeTimeCheckNode = null


static func create_from_tcheck_node(node : SuntomeTimeCheckNode) -> SuntomeTimeCheckNodePanel:
	var ctrl : SuntomeTimeCheckNodePanel= preload("res://editor/normal_suntome_node/suntome_time_check_node_panel.tscn").instantiate()
	ctrl._ref_node = node
	ctrl._set_time(node.checked_time)
	ctrl._set_text(node.checked_time_tag)
	return ctrl


#通用接口
static func create_ctt_from_node(
		parent : StateNode,
		node : SuntomeTimeCheckNode
		) -> SuntomeContainerContent:
	if null == node:
		return

	var ctt := SuntomeContainerContent.create_ctt_from_state_and_node(parent, node)

	var panel : SuntomeTimeCheckNodePanel = create_from_tcheck_node(node)
	panel._ref_node = node
	ctt.connect_contained(panel)
	return ctt


func _ready() -> void:
	%TimeInputControl.value_changed.connect(func(value : float):
		if _ref_node:
			_ref_node.checked_time = value
	)

	%tag.about_to_popup.connect(func():
		#获取所有选项列表
		#遍历所有的suntome_node，将所有的选项集合
		var keys := Dictionary()
		for node in SuntomeGlobal.suntome_nodes.values():
			if node is SuntomeTimeBeginNode:
				keys.set(node.time_tag, null)

		#基于集合构建tag的下拉菜单
		var popup : PopupMenu = %tag.get_popup()
		popup.clear(true)
		for key in keys.keys():
			popup.add_item(key)
		pass
	)

	%tag.get_popup().index_pressed.connect(
		func(bindex : int):
			var checktext = %tag.get_popup().get_item_text(bindex)
			%tag.text = checktext
			_ref_node.checked_time_tag = checktext
	)
	pass


func _set_time(t : float):
	%TimeInputControl.value = t


func _set_text(t : String):
	if t.is_empty():
		return
	%tag.text = t


#和SuntomeContainerContent关联的函数
func node_text() -> String:
	return tr("Suntome Time Check", "node_name")


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
