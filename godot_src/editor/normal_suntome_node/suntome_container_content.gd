class_name SuntomeContainerContent extends VBoxContainer

#该content关联的SuntomeNode对象
var ref_suntome_node : SuntomeNodeBase

#容纳该对象的StateNode
var parent_node : StateNode

#实际的交互对象
var _contained_target : Control

static func create_ctt_from_state_and_node(
		parent : StateNode,
		node : SuntomeNodeBase
		) -> SuntomeContainerContent:
	if null == node:
		return

	var ctt : SuntomeContainerContent = preload("res://editor/normal_suntome_node/suntome_container_content.tscn").instantiate()
	ctt.ref_suntome_node = node
	ctt.update_para_node_content()
	ctt.parent_node = parent
	parent.get_container().add_child(ctt)
	#连接信号
	return ctt

func update_para_node_content():
	pass


func connect_contained(obj : Control):
	_contained_target = obj
	set_text(_contained_target.node_text())


func set_text(text : String):
	%Label.text = text


#拖拽相关函数（不支持拖拽
func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	return false


#和PlayNodeEditor联动的函数
#返回用户拖动节点连线时显示的线条信息
func get_drag_line_info() -> String:
	return _contained_target.get_drag_line_info()


#当连线连接时，判断是否可以连接
func line_connect_check() -> bool:
	return _contained_target.line_connect_check()


#处理和target相连的逻辑，仅当line_connect_check()返回true时才会执行该函数
func process_node_connect(target : SuntomeNodeBase):
	_contained_target.process_node_connect(target)


#处理和target断开连接的逻辑
func process_node_disconnect(target : SuntomeNodeBase):
	_contained_target.process_node_disconnect(target)


#获取该节点和其他节点的连线文本信息，该函数返回一个可调用的函数对象(other_node : SuntomeNodeBase) -> String
func get_connect_line_lable() -> Callable:
	return _contained_target.get_connect_line_lable()


#playnodeeditor会调用该函数来请求在参数栏显示节点参数
func show_node_param(parent : Container):
	for c in parent.get_children():
		parent.remove_child(c)

	parent.add_child(_contained_target)
