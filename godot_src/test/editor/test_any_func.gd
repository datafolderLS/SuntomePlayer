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

	print(Utility.file_name_without_suffix("./dafadsf/dfdfa/ddd"))
	print(Utility.file_name_without_suffix("./dafadsf/dfdfa/ddd."))
	print(Utility.file_name_without_suffix("./dafadsf/dfdfa/ddd.dd"))
	print(Utility.file_name_without_suffix("ddd.dd"))

	%rot_slider.value_changed.connect(_rot_slider_value_change)
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
	# sobj.nextNodes_button_to_uid = {"asdnfi" : 15, "asdnddfi" : 15, "as1521dnfi" : 15}

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


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			CusContentMenu.create(self, event.global_position, ["select 1", "select 2", "select3"].map(
				func(value : String):
					return CusContentMenu.bt(value, func(): print(value))
			)
			)


func _rot_slider_value_change(value : float):
	var now_angle = value / 360.0 * 2 * PI
	%now_rot.text = "{0} degree, {1} radian".format([value, now_angle])

	%rot_label.rotation = now_angle

	var pos_diff = StateLine._calc_control_pos_diff_in_rot_angle(%rot_label, true)
	%rot_label.position = pos_diff + Vector2(25, 0.0)
	# var y_diff_add = 10
	# var label_size = %rot_label.size
	# var side_angle = atan2(label_size.y , label_size.x)
	# var y_diff1 = label_size.length() * sin(now_angle + side_angle)
	# var y_diff2 = label_size.y * sin(now_angle + PI * 0.5)
	# var y_diff3 = label_size.x * sin(now_angle)
	# print("{0} {1}".format([y_diff3]))
	# var y_diff = min(y_diff1, y_diff2, y_diff3)
	# var x_diff_add = (cos(now_angle + PI)* 0.5 + 0.5) * label_size.x
	# if y_diff < 0.0:
	# 	%rot_label.position = Vector2(25 + x_diff_add, -y_diff + y_diff_add)
	# else:
	# 	%rot_label.position = Vector2(25 + x_diff_add, y_diff_add)
	pass
