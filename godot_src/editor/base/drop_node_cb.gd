class_name DropNodeCB extends Control

var drop_in_panel_availiable_func : Callable
var drop_in_panel_cb : Callable
var can_drop : bool = true

#拖拽相关函数
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not can_drop:
		return false

	if not drop_in_panel_availiable_func.is_valid():
		return false

	return drop_in_panel_availiable_func.call(at_position, data)

func _drop_data(at_position: Vector2, data: Variant):
	if not can_drop:
		return

	if drop_in_panel_cb.is_valid():
		drop_in_panel_cb.call(at_position, data)
	pass
