class_name PicObjList extends VBoxContainer

@onready var itemlist : ItemList = get_node("ItemList")
@onready var nameEdit : LineEdit = get_node("ItemList/NameEdit")

@export var allow_drag : bool

var last_button_time : float = -1000.0
var last_button_index : int = -1

signal select_change(new_obj : String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for obj_name in SuntomeGlobal.select_pic_contents:
		var index = add_new_obj()
		itemlist.set_item_text(index, obj_name)

	itemlist.item_clicked.connect(
		func (index: int, at_position: Vector2, mouse_button_index: int) :
			confirm_edit_obj_name(last_button_index, nameEdit.text)

			if MOUSE_BUTTON_LEFT != mouse_button_index:
				return

			if last_button_index != index:
				last_button_index = index
				last_button_time = -1

				select_change.emit(itemlist.get_item_text(index))
				return

			var now_time = Time.get_ticks_msec()
			if now_time - last_button_time < 1000:
				last_button_time = -1000
				start_edit_obj_name(index)
			else:
				last_button_time = now_time
			pass
	)

	itemlist.empty_clicked.connect(
		func(at_position: Vector2, mouse_button_index: int):
			confirm_edit_obj_name(last_button_index, nameEdit.text)
	)

	nameEdit.text_submitted.connect(
		func(new_text: String):
			confirm_edit_obj_name(last_button_index, new_text)
			pass
	)

	get_node("HBoxContainer/AddButton").pressed.connect(create_new_obj_content)
	get_node("HBoxContainer/RemoveButton").pressed.connect(remove_button_clicked)

	pass # Replace with function body.


func start_edit_obj_name(index : int):
	var text := itemlist.get_item_text(index)
	print("start edit pic obj in index :", index, " name: ", text)
	var rect := itemlist.get_item_rect(index, false)
	nameEdit.text = text
	nameEdit.position = rect.position
	rect.size.x = itemlist.size.y
	rect.size.y = rect.size.y - 2
	nameEdit.size = rect.size
	nameEdit.show()

	pass


#将new_text应用到index下标item的修改上，检查nameEdit是否可视，如果不可视则不应用修改，函数会隐藏nameEdit
func confirm_edit_obj_name(index : int, new_text: String):
	if not nameEdit.is_visible():
		return

	var preName = itemlist.get_item_text(index)
	if new_text != preName:
		pass
	nameEdit.hide()

	var nameList = get_all_obj_names()
	nameList.erase(preName)
	new_text = Utility.check_no_repeat_name(new_text, nameList)
	itemlist.set_item_text(index, new_text)
	print("confim select pic obj name to ", new_text)

	_update_select_pic_content_name(preName, new_text)

	pass


#创建新的obj对象
func create_new_obj_content():
	var i = add_new_obj()
	_add_new_select_pic_content(itemlist.get_item_text(i))


#在itemlist中添加一个新对象，并返回该对象在itemlist中的下标
func add_new_obj() -> int:
	var nameList = get_all_obj_names()
	var new_text = "new pic object"
	new_text = Utility.check_no_repeat_name(new_text, nameList)
	return itemlist.add_item(new_text)
	pass


func remove_button_clicked():
	var selected = itemlist.get_selected_items()
	if selected.is_empty():
		return

	var name = itemlist.get_item_text(selected[0])
	_remove_select_pic_content(name)

	itemlist.remove_item(selected[0])

	last_button_index = -1
	pass


func get_all_obj_names() -> Array:
	var list = []
	for i in range(itemlist.item_count) :
		list.push_back(itemlist.get_item_text(i))
	return list


func _add_new_select_pic_content(name : String):
	var new_cont = SelectPicContent.new()
	new_cont.name = name
	SuntomeGlobal.select_pic_contents[name] = new_cont
	pass


func _update_select_pic_content_name(name_before : String, name_after : String):
	if name_before == name_after:
		return

	var before = SuntomeGlobal.select_pic_contents[name_before]
	SuntomeGlobal.select_pic_contents[name_after] = before
	SuntomeGlobal.select_pic_contents.erase(name_before)
	before.change_name(name_after)
	pass


func _remove_select_pic_content(name : String):
	var needDelete = SuntomeGlobal.select_pic_contents[name]
	needDelete.before_delete()
	SuntomeGlobal.select_pic_contents.erase(name)


#拖拽实现
func _get_drag_data(at_position: Vector2) -> Variant:
	if not allow_drag:
		return null

	var index = get_node("ItemList").get_item_at_position(get_node("ItemList").get_local_mouse_position(), true)
	if index < 0:
		return null

	var text := itemlist.get_item_text(index)
	var label = Label.new()
	label.text = text

	set_drag_preview(label)
	return [text]
	pass
