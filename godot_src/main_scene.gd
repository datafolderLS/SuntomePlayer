extends Control

@onready var player = get_node("Player")

@onready var editor_container = get_node("%editor_container")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# var button : Button = get_node("Button_start_test")
	# var button2 : Button = get_node("Button2")
	# button.pressed.connect(_start_test_func)

	SuntomeGlobal.load_from_disc()

	#todo 检查控制台参数
	if OS.get_cmdline_args().has("--editor_mode") or OS.has_feature("editor"):
		editor_container.set_visible(false)
		var editor = preload("res://editor/editor.tscn").instantiate()
		editor_container.add_child(editor)

	SuntomePlayer.set_player(player)


	%button_omorashi.pressed.connect(func():
		print("omorashs")
		SuntomePlayer.omorashi_shita()
	)

	%Button_fullscreen_toggle.pressed.connect(_toggle_fullscreen)

	call_deferred("_start_test_func")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_TAB and event.pressed:
			editor_container.visible = not editor_container.visible


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
