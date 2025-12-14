extends Container

func _ready() -> void:
	%testbutton1.pressed.connect(_test1)
	%testbutton2.pressed.connect(_test2)

	var tree = FileTree.new_tree(SuntomeGlobal.root_path().path_join("data"))
	%HBoxContainer2.add_child(tree)
	%HBoxContainer2.move_child(tree,0)

	%PathBindForm.left_path_clicked.connect(func(p) : print(p))
	%PathBindForm.allow_drop_data_in_lrc_panel = func(at_position: Vector2, data: Variant) :
		if data is Array:
			if data[1] == FileTree.Type.File and data[2] == FileTree.AssetType.Subtitle:
				return true
			if data[1] == FileTree.Type.Folder:
				return true
		return false
	%PathBindForm.process_drop_data_in_lrc_panel = func(data, left_path, pre_right_data) :
		print(data)
		if left_path:
			print(left_path, pre_right_data)
			var lrc_file_path = data[0]
			if left_path.contains("Aim for") and lrc_file_path.contains("Aim for"):
				%PathBindForm.set_right_path_by_left_path(left_path, Utility.cut_file_path(lrc_file_path).erase(0, 7))
		pass

func _test1():

	# %PathBindForm.add_left_path("xxa/xxb/xxb/xxd")
	# %PathBindForm.add_left_path("xxa/xxb/xxb/xxcdd")
	%PathBindForm.add_left_path("xxa/xxa/xxd/ccc.cc" , "dafadsfasdfasdfa")
	%PathBindForm.add_left_path("xxa/xxa/xxa/ccc.cc")
	%PathBindForm.add_left_path("xxa/xxa/xxd/c/cc.cc")
	%PathBindForm.add_left_path("xxa/xxa/xxa/c/dc.cc")
	await get_tree().create_timer(0.5).timeout
	%PathBindForm.add_left_path("xxa/xxa/xxb.cc")
	# %PathBindForm.add_left_path("xxa/xxdd/xxdd")
	pass


func _test2():
	var root_path = SuntomeGlobal.root_path().path_join("data")
	var path_list := Array()
	FileTree.scan_folder(root_path, func(path : String, type : FileTree.Type):
		if type == FileTree.Type.File:
			var suffixCheck = Utility.file_suffix(path)
			if suffixCheck in GlobalSetting.SurportSoundTypes:
				path = Utility.cut_file_path(path).erase(0, 7)
				path_list.append(path)
			pass
		pass
		,true
	)
	# print(path_list)
	for path in path_list:
		%PathBindForm.add_left_path(path, "tt/" + path)
		await get_tree().create_timer(0.5).timeout

	pass
