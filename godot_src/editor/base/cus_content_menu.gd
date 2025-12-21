class_name CusContentMenu extends PopupPanel

#一个灵活的右键菜单控件，可以随时创建

class SelectInfo extends RefCounted:
	var text : String
	var cb : Callable


var _index_to_cb := Dictionary()


#构造一个CusContentMenu右键菜单，该节点会自动添加到/root节点下
static func create(nd : Node, global_pos : Vector2i, button_info : Array) -> CusContentMenu:
	var ctrl : CusContentMenu = preload("res://editor/base/cus_content_menu.tscn").instantiate()
	nd.get_node("/root").add_child(ctrl)
	ctrl.set_selections(button_info)
	ctrl.call_deferred("popup_in_correct_pos", global_pos)
	return null


static func bt(text : String, cb : Callable) -> SelectInfo:
	var info = SelectInfo.new()
	info.text = text
	info.cb = cb
	return info


func _ready() -> void:
	%ItemList.item_clicked.connect(_item_clicked)
	popup_hide.connect(func() : queue_free())


func set_selections(button_info : Array):
	%ItemList.clear()

	size = Vector2.ZERO

	for info : SelectInfo in button_info:
		var index = %ItemList.add_item(info.text)
		_index_to_cb.set(index, info.cb)
		pass

	%ItemList.update_minimum_size()
	pass


func _item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int):
	var cb = _index_to_cb.get(index)
	if cb:
		cb.call()
	hide()


func popup_in_correct_pos(emit_pos : Vector2i):
	var windowsize = DisplayServer.window_get_size()
	var self_size = size
	var prediff : Vector2i = windowsize -  emit_pos
	var size_diff : Vector2i = prediff - self_size
	var pos_diff : Vector2i = (size_diff - size_diff.abs()) / 2
	popup(Rect2i(emit_pos + pos_diff, Vector2i.ZERO))
	pass
