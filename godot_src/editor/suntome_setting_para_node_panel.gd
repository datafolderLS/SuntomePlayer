class_name SuntomeSettingParaNodePanel extends VBoxContainer

var _ref_node : SuntomeParaNode = null


static func create_from_setting_node(node : SuntomeParaNode):
	var ctrl = preload("res://editor/suntome_setting_para_node_panel.tscn").instantiate()
	ctrl._ref_node = node
	for key in node.change_operation:
		var value = node.change_operation[key]
		var parac = ctrl.make_param_ctrl(key, value)
		ctrl.get_node("%CtrlContainer").add_child(parac)
	return ctrl

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
