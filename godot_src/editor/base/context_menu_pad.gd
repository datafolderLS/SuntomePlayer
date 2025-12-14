extends Container

#用于组织右键菜单的控件

# var _button_cb_map := Dictionary()
var _bt_theme = preload("res://editor/base/context_menu_pad_theme/context_menu_pad_theme.tres")

func _ready() -> void:
	pass


#设置选项内容，list的成员类型为[selection_text, Callable]，前者作为选项显示，后者作为用户点击回调
func set_selections(list : Array):
	_clear_buttons()
	for item in list:
		var text : String = item[0]
		var cb : Callable = item[1]

		var bt = _make_button()
		%VBoxContainer.add_child(bt)
		bt.text = text
		# _button_cb_map.set(bt, cb)
		bt.pressed.connect(cb)
	set_size(Vector2.ZERO)
	pass


func _clear_buttons():
	# _button_cb_map.clear()
	var list = %VBoxContainer.get_children()
	for bt in list:
		%VBoxContainer.remove_child(bt)
		bt.queue_free()


func _make_button() -> Button:
	var bt = Button.new()
	bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
	bt.theme = _bt_theme
	return bt
