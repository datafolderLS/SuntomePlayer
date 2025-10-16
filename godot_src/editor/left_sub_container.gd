extends MarginContainer


@onready var sound_obj_list : SoundObjList = get_node("%SoundObjList")
@onready var content_container = get_node("%ContentContainer")
@onready var file_tree_container = get_node("%TreeContainer")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var path = SuntomeGlobal.root_path().path_join("data")
	var tree = FileTree.new_tree(path)
	file_tree_container.add_child(tree)
	#file_tree_container.move_child(tree, 0)

	#sound_obj_list.select_change.connect(
		#func(select_name : String):
			##if SuntomeGlobal.sound_object_contents.has(select_name):
				##var obj = SuntomeGlobal.sound_object_contents[select_name]
				##sound_obj_editor.set_sound_object(obj)
			#pass
	#)

	pass # Replace with function body.


func container() -> PanelContainer:
	return content_container


func set_dragable(dragable : bool):
	%PicObjList.allow_drag = dragable
	%SoundObjList.allow_drag = dragable
	pass


#修改左下角的菜单类型, 0是soundObj对象，1是PicObj对象
func change_leftcorner_list(change_mode : int):
	match change_mode:
		0 :
			%TabContainer.current_tab = %TabContainer.get_tab_idx_from_control(%SoundObjList)
		1 :
			%TabContainer.current_tab = %TabContainer.get_tab_idx_from_control(%PicObjList)
	pass
