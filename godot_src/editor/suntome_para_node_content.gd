class_name SuntomeParaNodeContent extends VBoxContainer

#该content关联的SuntomeNode对象
var ref_suntome_node : SuntomeParaNode

#容纳该对象的StateNode
var parent_node : StateNode

static var para_ctrl : SuntomeSettingParaNodePanel = null


static func create_ctt_from_para_node(
		parent : StateNode,
		node : SuntomeParaNode
		) -> SuntomeParaNodeContent:
	if null == node:
		return

	var ctt = preload("res://editor/suntome_para_node_content.tscn").instantiate()
	ctt.ref_suntome_node = node
	ctt.update_para_node_content()
	ctt.parent_node = parent
	parent.get_container().add_child(ctt)
	#连接信号
	return ctt

func update_para_node_content():
	pass


#拖拽相关函数（不支持拖拽
func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool: return false


#和PlayNodeEditor联动的函数
#返回用户拖动节点连线时显示的线条信息
func get_drag_line_info() -> String:
	if ref_suntome_node.nextNodes.is_empty():
		return "after setting"
	return "not allowed"


#当连线连接时，判断是否可以连接
func line_connect_check() -> bool:
	if ref_suntome_node.nextNodes.is_empty():
		return true
	return false


#处理和target相连的逻辑，仅当line_connect_check()返回true时才会执行该函数
func process_node_connect(target : SuntomeNodeBase):
	ref_suntome_node.nextNodes.set(target.uid, target)


#处理和target断开连接的逻辑
func process_node_disconnect(target : SuntomeNodeBase):
	ref_suntome_node.nextNodes.erase(target.uid)


#获取该节点和其他节点的连线文本信息，该函数返回一个可调用的函数对象(other_node : SuntomeNodeBase) -> String
func get_connect_line_lable() -> Callable:
	return func(_other_node : SuntomeNodeBase) -> String:
		return "after setting"


#playnodeeditor会调用该函数来请求在参数栏显示节点参数
func show_node_param(parent : Container):
	for c in parent.get_children():
		parent.remove_child(c)

	if null != para_ctrl:
		para_ctrl.queue_free()

	para_ctrl = SuntomeSettingParaNodePanel.create_from_setting_node(ref_suntome_node)
	parent.add_child(para_ctrl)
