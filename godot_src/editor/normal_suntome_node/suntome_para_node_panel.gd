class_name SuntomeParaNodePanel extends VBoxContainer

var _ref_node : SuntomeParaNode = null


static func create_from_setting_node(node : SuntomeParaNode) -> SuntomeParaNodePanel:
	var ctrl : SuntomeParaNodePanel = preload("res://editor/normal_suntome_node/suntome_para_node_panel.tscn").instantiate()
	ctrl._ref_node = node
	for key in node.change_operation:
		var value = node.change_operation[key]
		var parac = ctrl.make_param_ctrl(key, value)
		ctrl.get_node("%CtrlContainer").add_child(parac)
	return ctrl


static func create_ctt_from_node(
		parent : StateNode,
		node : SuntomeParaNode
		) -> SuntomeContainerContent:
	if null == node:
		return

	var ctt := SuntomeContainerContent.create_ctt_from_state_and_node(parent, node)

	var panel : SuntomeParaNodePanel = create_from_setting_node(node)
	panel._ref_node = node
	ctt.connect_contained(panel)
	return ctt


func _ready() -> void:
	%button_add.pressed.connect(_add_param)
	pass


func make_param_ctrl(key : String, value : float)->ParaNodeSettingCtrl:
	var ctrl = ParaNodeSettingCtrl.create(key)
	ctrl.get_node("%SpinBox").value = value
	ctrl.get_all_other_text = Callable(self, "all_setting")
	ctrl.text_change.connect(_text_change)
	ctrl.req_delete.connect(_delelte_ctrl)
	ctrl.value_change.connect(_update_value)
	return ctrl


func _add_param():
	var nname = Utility.check_no_repeat_name("para", all_setting())
	var ctrl = make_param_ctrl(nname, 0)
	%CtrlContainer.add_child(ctrl)
	_ref_node.change_operation.set(nname, ctrl.value())
	pass


func all_setting():
	return _ref_node.change_operation.keys()


func _text_change(pretext : String, text : String):
	var value = _ref_node.change_operation[pretext]
	_ref_node.change_operation.erase(pretext)
	_ref_node.change_operation.set(text, value)


func _delelte_ctrl(ctrl : ParaNodeSettingCtrl):
	var key = ctrl.current_text()
	_ref_node.change_operation.erase(key)
	%CtrlContainer.remove_child(ctrl)
	ctrl.queue_free()


func _update_value(ctrl : ParaNodeSettingCtrl, value : float):
	var key = ctrl.current_text()
	_ref_node.change_operation.set(key, value)


#和SuntomeContainerContent关联的函数
func node_text() -> String:
	return tr("ParaSettingNode", "node_name")


#和PlayNodeEditor联动的函数
#返回用户拖动节点连线时显示的线条信息
#返回用户拖动节点连线时显示的线条信息
func get_drag_line_info() -> String:
	if _ref_node.nextNodes.is_empty():
		return tr("after setting")
	return tr("not allowed")


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
		return tr("after setting")
