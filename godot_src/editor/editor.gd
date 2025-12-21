extends Container


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TranslationServer.set_locale("ja")

	var sub_container = get_node("%LeftSubContainer")
	var panelContainer : PanelContainer = sub_container.container()

	var nodeSoundEditor = preload("res://editor/base/sound_obj_edit.tscn").instantiate()
	var playNodeEditor = preload("res://editor/play_node_editor.tscn").instantiate()
	var picObjEditor = preload("res://editor/select_pic_editor.tscn").instantiate()
	var subtitleBind = preload("res://editor/subtitle_bind_editor.tscn").instantiate()

	nodeSoundEditor.connect_sound_obj_list(sub_container.sound_obj_list)

	sub_container.pic_obj_list.select_change.connect(
		func(select_name : String):
			if SuntomeGlobal.select_pic_contents.has(select_name):
				var obj = SuntomeGlobal.select_pic_contents[select_name]
				picObjEditor.set_current_pic_content(obj)
			pass
	)

	panelContainer.add_child(nodeSoundEditor)
	panelContainer.add_child(playNodeEditor)
	panelContainer.add_child(picObjEditor)
	panelContainer.add_child(subtitleBind)

	playNodeEditor.set_visible(false)
	picObjEditor.set_visible(false)
	subtitleBind.set_visible(false)
	nodeSoundEditor.set_visible(true)

	var invisibalAll = func() :
		playNodeEditor.set_visible(false)
		picObjEditor.set_visible(false)
		nodeSoundEditor.set_visible(false)
		subtitleBind.set_visible(false)


	get_node("%button_PlayNodeEdit").pressed.connect(
		func():
			sub_container.set_dragable(true)
			invisibalAll.call()
			playNodeEditor.set_visible(true)
	)

	get_node("%button_SoundObjEdit").pressed.connect(
		func():
			sub_container.set_dragable(false)
			invisibalAll.call()
			nodeSoundEditor.set_visible(true)
			%LeftSubContainer.change_leftcorner_list(0)
	)

	get_node("%button_SelectPicNodeEdit").pressed.connect(
		func():
			sub_container.set_dragable(false)
			invisibalAll.call()
			picObjEditor.set_visible(true)
			%LeftSubContainer.change_leftcorner_list(1)
			pass
	)

	get_node("%button_SubtitleEdit").pressed.connect(
		func():
			sub_container.set_dragable(false)
			invisibalAll.call()
			subtitleBind.set_visible(true)
			pass
	)

	get_node("%ButtonSave").pressed.connect(
		func():
			SuntomeGlobal.save()
			pass
	)


	#响应点击信息
	# sub_container.get_FileTreeNode().on_select_file_change.connect(
	# 	func(path : String, type : FileTree.AssetType):
	# 		if FileTree.AssetType.Sound == type:
	# 			subtitleBind.set_current_sound(path)
	# )

	%button_language.get_popup().id_pressed.connect(
		func(id : int):
			match id:
				0: #English
					TranslationServer.set_locale("en")
					pass
				1: #Japnese
					TranslationServer.set_locale("ja")
					pass
			pass
	)

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
