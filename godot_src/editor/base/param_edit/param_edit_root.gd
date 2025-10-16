class_name ParamEditRoot extends Node

#用于和ParamEditControl组合的Object属性修改绑定器

#用于ParamEditControl获取对象，该函数为func () -> Object
var get_value : Callable

signal value_changed(param_name : String, value)


func _ready() -> void:
	var allNodes = Utility.node_all_children(self)
	for ctrl in allNodes:
		if ctrl is ParamEditControl or ctrl is SliderOfVector2:
			ctrl.value_updated = func(para_name : String, value : Variant):
				# print(para_name, "   ", value)
				value_changed.emit(para_name, value)
				pass
	pass

#呼叫子ParamEditControl控件对象更新数据
func refresh():
	if not get_value.is_valid():
		return

	var obj = get_value.call()

	if null == obj:
		return

	var allNodes = Utility.node_all_children(self)
	for ctrl in allNodes:
		if ctrl is ParamEditControl:
			ctrl.refresh(obj)
		elif ctrl is SliderOfVector2:
			ctrl.refresh(obj)
			pass
	pass


func update():
	if not get_value.is_valid():
		return

	var obj = get_value.call()

	if null == obj:
		return

	var allNodes = Utility.node_all_children(self)
	# var allNodes = get_children(true)
	for ctrl in allNodes:
		if ctrl is ParamEditControl:
			ctrl.update_value(obj)
		elif ctrl is SliderOfVector2:
			ctrl.update_value(obj)
			pass
	pass
