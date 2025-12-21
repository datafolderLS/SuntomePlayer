class_name ObjList extends VBoxContainer


static func construct(name_ : String, item_list : Callable) -> ObjList:
	var list = preload("res://editor/base/obj_list.tscn").instantiate()
	list.get_node("%label_name").text = ""
	list.name = name_
	list._get_all_item = item_list
	# list._init_after_ready()
	return list


@onready var itemlist : ItemList = get_node("ItemList")
@onready var nameEdit : LineEdit = get_node("%NameEdit")

@export var allow_drag : bool

var last_button_time : float = -1000.0
var last_button_index : int = -1

signal select_change(new_obj : String)

var _get_all_item : Callable = Callable()

#需要调用者赋值的函数，
#添加新对象，参数(name : String) -> void
var add_new_item_cb : Callable = Callable()
#修改对象名称，参数(name_before : String, name_after : String) -> void
var change_item_name_cb : Callable = Callable()
#删除对象，参数(name : String) -> void
var delete_item_cb : Callable = Callable()
#构建拖拽对象，参数(item_name : String, f_set_drag_preview : Callable) -> Variant
var make_drag_data_cb : Callable = Callable()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_after_ready()
	pass


func _init_after_ready():
	var all_items = _get_all_item.call()
	for obj_name in all_items:
		var index = add_new_obj()
		itemlist.set_item_text(index, obj_name)

	itemlist.item_clicked.connect(
		func (index: int, _at_position: Vector2, mouse_button_index: int) :
			confirm_edit_obj_name(last_button_index, nameEdit.text)

			if MOUSE_BUTTON_LEFT != mouse_button_index:
				return

			if last_button_index != index:
				last_button_index = index
				last_button_time = -1

				select_change.emit(itemlist.get_item_text(index))
				# return

			var now_time = Time.get_ticks_msec()
			if now_time - last_button_time < 1000:
				last_button_time = -1000
				start_edit_obj_name(index)
			else:
				last_button_time = now_time
			pass
	)

	itemlist.empty_clicked.connect(
		func(_at_position: Vector2, _mouse_button_index: int):
			confirm_edit_obj_name(last_button_index, nameEdit.text)
	)

	nameEdit.text_submitted.connect(
		func(new_text: String):
			confirm_edit_obj_name(last_button_index, new_text)
			pass
	)

	get_node("HBoxContainer/AddButton").pressed.connect(create_new_obj_content)
	get_node("HBoxContainer/RemoveButton").pressed.connect(remove_button_clicked)

	itemlist.gui_input.connect(_item_list_gui_input)
	pass # Replace with function body.


func _item_list_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		get_viewport().set_input_as_handled()
		if event.is_pressed():
			match event.keycode:
				KEY_UP:
					var next_index = last_button_index - 1
					if next_index < 0:
						return
					last_button_index = next_index
					itemlist.select(last_button_index)
					select_change.emit(itemlist.get_item_text(last_button_index))
					pass
				KEY_DOWN:
					var next_index = last_button_index + 1

					if next_index >= itemlist.item_count:
						return

					last_button_index = next_index
					itemlist.select(last_button_index)
					select_change.emit(itemlist.get_item_text(last_button_index))
					pass
				KEY_F2:
					if last_button_index < 0 or last_button_index >= itemlist.item_count:
						return

					start_edit_obj_name(last_button_index)
					pass
	pass


func start_edit_obj_name(index : int):
	var text := itemlist.get_item_text(index)
	print("start edit obj in index :", index, " name: ", text)
	var rect := itemlist.get_item_rect(index, false)
	nameEdit.text = text
	var y_diff = 0.0
	for ctrl in itemlist.get_children(true):
		if ctrl is VScrollBar:
			y_diff = -ctrl.value
			break

	rect.size.x = itemlist.size.x
	rect.position += Vector2(0, y_diff) + itemlist.get_global_rect().position
	%PopupPanel.popup(Rect2i(rect))
	# nameEdit.position = rect.position + Vector2(0, y_diff)


	# nameEdit.size = rect.size
	# nameEdit.show()
	nameEdit.edit()
	pass


#将new_text应用到index下标item的修改上，检查nameEdit是否可视，如果不可视则不应用修改，函数会隐藏nameEdit
func confirm_edit_obj_name(index : int, new_text: String):
	if not %PopupPanel.visible:
		return

	var preName = itemlist.get_item_text(index)
	if new_text != preName:
		pass

	var nameList = get_all_obj_names()
	nameList.erase(preName)
	new_text = Utility.check_no_repeat_name(new_text, nameList)
	itemlist.set_item_text(index, new_text)
	print("confim obj name to ", new_text)

	_update_select_pic_content_name(preName, new_text)
	%PopupPanel.hide()

	itemlist.grab_focus()
	pass


#创建新的obj对象
func create_new_obj_content():
	var i = add_new_obj()
	_add_new_select_pic_content(itemlist.get_item_text(i))
	itemlist.grab_focus()


#在itemlist中添加一个新对象，并返回该对象在itemlist中的下标
func add_new_obj() -> int:
	var nameList = get_all_obj_names()
	var new_text = "new object"
	new_text = Utility.check_no_repeat_name(new_text, nameList)
	return itemlist.add_item(new_text)


func remove_button_clicked():
	var selected = itemlist.get_selected_items()
	if selected.is_empty():
		return

	var name_ = itemlist.get_item_text(selected[0])
	_remove_select_pic_content(name_)

	itemlist.remove_item(selected[0])

	if itemlist.item_count <= 0:
		last_button_index = -1
	else:
		last_button_index = min(last_button_index, itemlist.item_count - 1)
		itemlist.select(last_button_index)
		select_change.emit(itemlist.get_item_text(last_button_index))

	itemlist.grab_focus()
	pass


func get_all_obj_names() -> Array:
	var list = []
	for i in range(itemlist.item_count) :
		list.push_back(itemlist.get_item_text(i))
	return list


func _add_new_select_pic_content(name_ : String):
	add_new_item_cb.call(name_)
	# var new_cont = SelectPicContent.new()
	# new_cont.name = name
	# SuntomeGlobal.select_pic_contents[name] = new_cont
	pass


func _update_select_pic_content_name(name_before : String, name_after : String):
	if name_before == name_after:
		return

	change_item_name_cb.call(name_before, name_after)
	# var before = SuntomeGlobal.select_pic_contents[name_before]
	# SuntomeGlobal.select_pic_contents[name_after] = before
	# SuntomeGlobal.select_pic_contents.erase(name_before)
	# before.change_name(name_after)
	pass


func _remove_select_pic_content(name_ : String):
	print("delete item \"", name_, "\"")
	delete_item_cb.call(name_)
	# var needDelete = SuntomeGlobal.select_pic_contents[name]
	# needDelete.before_delete()
	# SuntomeGlobal.select_pic_contents.erase(name)


#拖拽实现
func _get_drag_data(_at_position: Vector2) -> Variant:
	if not allow_drag:
		return null

	var index = get_node("ItemList").get_item_at_position(get_node("ItemList").get_local_mouse_position(), true)
	if index < 0:
		return null

	var text := itemlist.get_item_text(index)

	var data = make_drag_data_cb.call(text, func(preview_node) : set_drag_preview(preview_node))
	# var label = Label.new()
	# label.text = text

	# set_drag_preview(label)
	return data
