extends MarginContainer


@onready var content_container = get_node("%ContentContainer")
@onready var file_tree_container = get_node("%TreeContainer")

var pic_obj_list : ObjList = null
var sound_obj_list : ObjList = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	@warning_ignore_start("STATIC_CALLED_ON_INSTANCE")
	var path = SuntomeGlobal.root_path().path_join("data")
	@warning_ignore_restore("STATIC_CALLED_ON_INSTANCE")

	var tree = FileTree.new_tree(path)
	file_tree_container.add_child(tree)
	#file_tree_container.move_child(tree, 0)

	pic_obj_list = ObjList.construct("PicObjList",
		func():
			return SuntomeGlobal.select_pic_contents.keys()
	)

	pic_obj_list.add_new_item_cb = func(new_name : String):
		var new_cont = SelectPicContent.new()
		new_cont.name = new_name
		SuntomeGlobal.select_pic_contents[new_name] = new_cont

	pic_obj_list.change_item_name_cb = func(name_before : String, name_after : String):
		var before = SuntomeGlobal.select_pic_contents[name_before]
		SuntomeGlobal.select_pic_contents[name_after] = before
		SuntomeGlobal.select_pic_contents.erase(name_before)
		before.change_name(name_after)

	pic_obj_list.delete_item_cb = func(del_name : String):
		var needDelete = SuntomeGlobal.select_pic_contents[del_name]
		needDelete.before_delete()
		SuntomeGlobal.select_pic_contents.erase(del_name)

	pic_obj_list.make_drag_data_cb = func(item_name : String, f_set_drag_preview : Callable) -> Variant:
		var label = Label.new()
		label.text = item_name
		f_set_drag_preview.call(label)
		return [item_name]


	sound_obj_list = ObjList.construct("SoundObjList", func(): return SuntomeGlobal.sound_object_contents.keys())

	sound_obj_list.add_new_item_cb = func(new_name : String):
		var new_cont = SoundObjContent.new()
		new_cont.name = new_name
		SuntomeGlobal.sound_object_contents[new_name] = new_cont

	sound_obj_list.change_item_name_cb = func(name_before : String, name_after : String):
		var before = SuntomeGlobal.sound_object_contents[name_before]
		SuntomeGlobal.sound_object_contents[name_after] = before
		SuntomeGlobal.sound_object_contents.erase(name_before)
		before.change_name(name_after)

	sound_obj_list.delete_item_cb = func(del_name : String):
		var needDelete = SuntomeGlobal.sound_object_contents[del_name]
		needDelete.before_delete()
		SuntomeGlobal.sound_object_contents.erase(del_name)

	sound_obj_list.make_drag_data_cb = func(item_name : String, f_set_drag_preview : Callable) -> Variant:
		var label = Label.new()
		label.text = item_name
		f_set_drag_preview.call(label)
		return item_name

	%TabContainer.add_child(sound_obj_list)
	%TabContainer.add_child(pic_obj_list)

	pass # Replace with function body.


func container() -> PanelContainer:
	return content_container


func set_dragable(dragable : bool):
	sound_obj_list.allow_drag = dragable
	pic_obj_list.allow_drag = dragable
	pass


#修改左下角的菜单类型, 0是soundObj对象，1是PicObj对象
func change_leftcorner_list(change_mode : int):
	match change_mode:
		0 :
			%TabContainer.current_tab = %TabContainer.get_tab_idx_from_control(sound_obj_list)
		1 :
			# %TabContainer.current_tab = %TabContainer.get_tab_idx_from_control(%PicObjList)
			%TabContainer.current_tab = %TabContainer.get_tab_idx_from_control(pic_obj_list)
	pass


func get_FileTreeNode() -> FileTree:
	return file_tree_container.get_child(0)
