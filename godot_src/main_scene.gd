extends Control

@onready var player = get_node("Player")

@onready var editor_container = get_node("%editor_container")

var quit_func := Callable()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TranslationServer.set_locale("ja")
	AutoSizeLabelManager.locale_chaged()
	# var button : Button = get_node("Button_start_test")
	# var button2 : Button = get_node("Button2")
	# button.pressed.connect(_start_test_func)
	SuntomeGlobal.load_from_disc()

	#todo 检查控制台参数
	var is_in_editor = OS.get_cmdline_args().has("--editor_mode") or OS.has_feature("editor")
	if is_in_editor:
		editor_container.set_visible(false)
		var editor = preload("res://editor/editor.tscn").instantiate()
		editor_container.add_child(editor)
		get_tree().set_auto_accept_quit(false)
		quit_func = func():
			return await _check_if_save_or_not_before_close()
	else:
		SuntomePlayer.playoverfunc = _start_test_func

	SuntomePlayer.set_player(player)

	%button_omorashi.pressed.connect(func():
		print("omorashs")
		SuntomePlayer.omorashi_shita()
	)

	%Button_fullscreen_toggle.pressed.connect(_toggle_fullscreen)

	if not is_in_editor:
		call_deferred("_start_test_func")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		match event.keycode:
			KEY_TAB:
				if event.pressed:
					editor_container.visible = not editor_container.visible
			KEY_F4:
				if event.pressed and Input.is_key_pressed(KEY_ALT):
					get_tree().quit() # 紧急退出


func _button_pressed():
	#if OS.has_feature("editor") :
		#var img = load("res://image092.jpg") as Texture2D
#
		#if null == img:
			#return
		#player.play_next(img, AudioStreamMP3.load_from_file("res://MusMus-BGM-014.mp3"))
		#pass
	#else:
		#var path = OS.get_executable_path().get_base_dir()
		#print(path)
		#var img = Image.load_from_file(path.path_join("testimage.png"))
		#var tex = ImageTexture.create_from_image(img) as Texture2D
#
		#if null == tex:
			#return
		#player.play_next(tex, AudioStreamMP3.load_from_file(path.path_join("MusMus-BGM-014.mp3")))
		pass

func _start_test_func():
	SuntomePlayer.start_from_node(SuntomeGlobal.begin_node)
	pass


func _toggle_fullscreen():
	var root : Window = get_node("/root")
	var curmode : DisplayServer.WindowMode = DisplayServer.window_get_mode(root.get_window_id())
	if DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN == curmode:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED, root.get_window_id())
		root.borderless = false
	else :
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN, root.get_window_id())
	pass


#处理退出信号
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not quit_func.is_valid():
			get_tree().quit() # default behavior
		else:
			if Input.is_key_pressed(KEY_ALT):
				pass #do nothing
			elif await quit_func.call():
				get_tree().quit() # 确认是否保存


func _check_if_save_or_not_before_close() -> bool:
	var dialog = ConfirmationDialog.new()
	dialog.ok_button_text = tr("Yes", "exit_dialog")
	dialog.cancel_button_text = tr("No", "exit_dialog")
	var bt = dialog.add_cancel_button(tr("Cancel", "exit_dialog"))
	dialog.dialog_text = tr("Are you sure to save and exit Editor?", "exit_dialog")
	add_child(dialog)

	var temp = [false]

	dialog.get_ok_button().button_down.connect(func():
		temp[0] = true
		SuntomeGlobal.save()
	)

	dialog.get_cancel_button().button_down.connect(func():
		temp[0] = true
	)

	dialog.popup_centered()
	bt.grab_focus()
	await dialog.visibility_changed
	pass
	return temp[0]
