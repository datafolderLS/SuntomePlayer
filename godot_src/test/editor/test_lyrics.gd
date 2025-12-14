extends Node2D

@onready var dialog = FileDialog.new()

var openfilecb : Callable = Callable()

var prelyric : String = ""
var playing : bool = false
var data : SubtitleData = null

func _ready() -> void:
	dialog.title = "open file"
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.root_subfolder = Utility.relative_to_full("./data")
	dialog.display_mode = FileDialog.DISPLAY_LIST
	dialog.file_selected.connect(
		func(path : String):
			if openfilecb.is_valid():
				openfilecb.call(path)
	)

	%Button_Openfile.add_child(dialog)

	%Button_Openfile.pressed.connect(
		func():
			openfilecb = func(path : String):
				print(path)
				data = SubtitleData.construct_from_file(path)
				_add_space_in_lyrics(data, 1.0)
				if data.errorinfo:
					print(data.errorinfo)
					data = null
					%SubtitleMultiViewer.set_subtitledata(null)
				else:
					%SubtitleMultiViewer.set_subtitledata(data)
					for i in data._data:
						print(i.start_time, " ", i.end_time, " ", i.substr)

			dialog.popup_centered()
			pass
	)

	%Button_playaudio.pressed.connect(
		func():
			openfilecb = func(path : String):
				print(path)
				var sound = _sound_load(path)
				if sound:
					%AudioStreamPlayer.stream = sound
					%AudioStreamPlayer.play()
					playing = true

					%SubtitleViewer.get_now_subtitle = func():
						if %AudioStreamPlayer.is_playing():
							var pos = %AudioStreamPlayer.get_playback_position()
							var strr = data.lyric_in_pos(pos)
							return strr
						return ""

					%SubtitleMultiViewer.get_now_time = func():
						if %AudioStreamPlayer.is_playing():
							return %AudioStreamPlayer.get_playback_position()
						return 0.0


			dialog.popup_centered()
			pass
	)


func _process(_delta: float) -> void:
	pass


#加载音频文件
func _sound_load(path : String) -> AudioStream:
	# var abpath = Utility.relative_to_full(path)
	# if not FileAccess.file_exists(abpath):
	# 	push_error("sound path not valid: ", abpath)
	# 	return null

	# # var suffix
	# var suffixCheck = path.rsplit(".", true, 1)
	# var type = suffixCheck[1].to_lower()
	# if type not in GlobalSetting.SurportSoundTypes:
	# 	return null

	# if "wav" == type:
	# 	return AudioStreamWAV.load_from_file(abpath)
	# elif "ogg" == type:
	# 	return AudioStreamOggVorbis.load_from_file(abpath)
	# elif "mp3" == type:
	# 	return AudioStreamMP3.load_from_file(abpath)
	return Utility.load_supported_audio(path)


func _add_space_in_lyrics(dd : SubtitleData, space : float):
	for lyric in dd._data:
		var b = lyric.start_time
		var e = lyric.end_time
		lyric.end_time = max(e - space, b)
