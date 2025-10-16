extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%Button.pressed.connect(_test_2)
	%ParaNodeSettingCtrl.get_all_other_text = func():
		var list = ["1231", "卧槽", "おわり"]
		list.append(%ParaNodeSettingCtrl.current_text())
		return list
	%ParaNodeSettingCtrl.text_change.connect(func(pretext : String, text : String):
		print(pretext, " ", text)
	)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _test_1():
	print_debug("")

	var test = SuntomeNode.new_node()
	var others = range(2).map(func(_i : int) : return SuntomeNode.new_node())
	for i in others :
		test.nextNodes.set(i.uid, i)

	test.check_chance_index_data()

	test.play_mode = Utility.RandomHelper.Method.RandomNoRepeat

	for _i in range(20):
		print(test.get_next_node().uid)
	pass

func _test_2():
	# _test_SoundObjContent_serialize()
	_test_SelectPicContent_serialize()


func _test_SoundObjContent_serialize():
	var sobj = SoundObjContent.new()
	sobj.name = "1351adsf"

	var info = SoundObjContent.NodeInfo.new()
	info.offset_pos = Vector2(30,30)
	info.path = "path dadfdaffd"
	info.has_connected = true

	sobj.sound_nodes.append(info)
	sobj.sound_nodes.append(info)
	sobj.out_offset_pos = Vector2(32,32)
	sobj.play_method = Utility.RandomHelper.Method.RandomNoRepeat
	sobj.is_temp = true

	var dict = sobj.serialize()
	print(dict)
	sobj = SoundObjContent.new()
	# var error = sobj.unserialize(dict)
	var error = sobj.unserialize(Dictionary())
	print(error)
	dict = sobj.serialize()
	print(dict)


func _test_SelectPicContent_serialize():
	var sobj := SelectPicContent.new()
	sobj.name = "1351adsf"
	sobj.usedTexturePath = "path asdnifdn"
	sobj.nextNodes_button_to_uid = {"asdnfi" : 15, "asdnddfi" : 15, "as1521dnfi" : 15}

	var info = SelectPicContent.SelectButtonInfo.new()
	info.pos = Vector2(30,30)
	info.size = Vector2(30,30)
	info.bgcolor = Color.BLUE
	info.name = "1351adsf"
	info.name_as_text = true
	info.text = "1351adsf"
	info.fontcolor = Color.YELLOW
	info.isPicture = true
	info.picpath = "path picpath"

	sobj.buton_index.set(info.name, info)

	info = SelectPicContent.SelectButtonInfo.new()
	info.pos = Vector2(30,30)
	info.size = Vector2(30,30)
	info.bgcolor = Color.BLUE
	info.name = "1da851df"
	info.name_as_text = true
	info.text = "1351adsf"
	info.fontcolor = Color.YELLOW
	info.isPicture = true
	info.picpath = "path picpath"

	sobj.buton_index.set(info.name , info)

	var dict = sobj.serialize()
	print(dict)
	sobj = SelectPicContent.new()
	var error = sobj.unserialize(dict)
	# var error = sobj.unserialize(Dictionary())
	print(error)
	dict = sobj.serialize()
	print(dict)
	pass
