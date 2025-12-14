extends MarginContainer


var cur_SubtitleData : SubtitleData = null

func _ready() -> void:
	%SubtitleMultiViewer.get_now_time = func():
		return %AudioStreamPlayer.get_playback_position()

	%SoundBar.req_play_state_change.connect(
		func(playing : bool):
			if null == %AudioStreamPlayer.stream:
				if playing:
					_play_audio(%sound_path.text)
					pass
			else:
				%AudioStreamPlayer.set_stream_paused(not playing)
	)

	%SoundBar.req_time_change.connect(
		func(time : float):
			%AudioStreamPlayer.seek(time)
	)

	@warning_ignore_start("static_called_on_instance")
	var root_path = SuntomeGlobal.root_path().path_join("data")
	@warning_ignore_restore("static_called_on_instance")
	var path_list := Array()
	FileTree.scan_folder(root_path, func(path : String, type : FileTree.Type):
		if type == FileTree.Type.File:
			var suffixCheck = path.rsplit(".", true, 1)
			if suffixCheck[1].to_lower() in GlobalSetting.SurportSoundTypes:
				path = Utility.cut_file_path(path)
				path_list.append(path)
		pass
		,true
	)

	for path in path_list:
		var right_path = SuntomeGlobal.sound_subtitle_bind_info.get(path)
		%PathBindForm.add_left_path(path.erase(0,7), right_path if right_path else "")

	%PathBindForm.left_path_clicked.connect(func(path : String):
		set_current_sound(_bind_path_to_relative(path))
	)

	%PathBindForm.allow_drop_data_in_lrc_panel = func(_at_position: Vector2, data: Variant) :
		if data is Array:
			if data[1] == FileTree.Type.File and data[2] == FileTree.AssetType.Subtitle:
				return true
			if data[1] == FileTree.Type.Folder:
				return true
		return false

	%PathBindForm.process_drop_data_in_lrc_panel = func(data, left_path, pre_right_data) :
		#判断是不是文件夹
		if data[1] == FileTree.Type.Folder:
			#文件夹的拖动绑定需要特殊的逻辑
			var folderpath : String = data[0]
			var all_near_lrc_in_folder = _get_lrc_file_paths_in_folder(folderpath)
			var match_result = _auto_match_lrcs_to_audio(all_near_lrc_in_folder)
			# print(match_result)
			for a_path in match_result:
				var l_path = match_result[a_path]

				%PathBindForm.set_right_path_by_left_path(
					_relative_path_to_bind_path(a_path),
					_relative_path_to_bind_path(l_path)
				)
				SuntomeGlobal.sound_subtitle_bind_info.set(a_path, l_path)
			pass
		else:
			if left_path:
				print(left_path, pre_right_data)
				var lrc_file_path = Utility.cut_file_path(data[0])
				%PathBindForm.set_right_path_by_left_path(left_path, _relative_path_to_bind_path(lrc_file_path))
				SuntomeGlobal.sound_subtitle_bind_info.set(_bind_path_to_relative(left_path), lrc_file_path)
				if _bind_path_to_relative(left_path) == %sound_path.text:
					_load_lrc_from_path(lrc_file_path)
				pass
		pass

	# %drop_panel.drop_in_panel_availiable_func = func(_at_position: Vector2, data: Variant) -> bool:
	# 	if typeof(data) == TYPE_ARRAY and data.size() <= 2:
	# 		return false
	# 	if typeof(data) == TYPE_ARRAY and data[2] == FileTree.AssetType.Subtitle:
	# 		return true
	# 	return false

	# %drop_panel.drop_in_panel_cb = func(_at_position: Vector2, data: Variant):
	# 	var subpath = data[0]
	# 	_load_lrc_from_path(subpath)
	# 	# SuntomeGlobal.sound_subtitle_bind_info.set(%sound_path.text, Utility.cut_file_path(subpath))
	# pass


func _process(_delta: float) -> void:
	if %AudioStreamPlayer.is_playing():
		var curtime = %AudioStreamPlayer.get_playback_position()
		var totaltime = %AudioStreamPlayer.stream.get_length()
		%SoundBar.update_audio_time(curtime, totaltime)


# #设置当前编辑的音频绑定信息
func set_current_sound(path : String):
	path = Utility.cut_file_path(path)
	if path == %sound_path.text:
		return

	%sound_path.text = path

	%SoundBar.change_play_state_without_signal(false)
	%SoundBar.update_audio_time(0.0,1.0)

	#清空stream
	%AudioStreamPlayer.stop()
	%AudioStreamPlayer.stream = null

	#todo 获取和该文本绑定的字幕信息
	var subpath = SuntomeGlobal.sound_subtitle_bind_info.get(path)
	if null == subpath:
		# %subtitle_path.text = "no subtitle yet"
		%SubtitleMultiViewer.set_subtitledata(null)
		return

	_load_lrc_from_path(subpath)
	pass


func _play_audio(path : String):
	#读取音频文件
	var audio = Utility.load_supported_audio(path)
	if null == audio:
		%AudioStreamPlayer.stream = null
		%SoundBar.change_play_state_without_signal(false)
		#弹出错误信息
		return

	%AudioStreamPlayer.stream = audio
	%AudioStreamPlayer.play()


func _load_lrc_from_path(path : String):
	var data = SubtitleData.construct_from_file(path)
	if data.errorinfo:
		print(data.errorinfo)
		cur_SubtitleData = null
		%SubtitleMultiViewer.set_subtitledata(null)
	else:
		cur_SubtitleData = data
		# %subtitle_path.text = Utility.cut_file_path(path)
		%SubtitleMultiViewer.set_subtitledata(cur_SubtitleData)
	pass


func _relative_path_to_bind_path(path : String) -> String:
	return path.erase(0, 7)


func _bind_path_to_relative(path : String) -> String:
	return "./data/" + path


func _get_lrc_file_paths_in_folder(folder_path : String) -> Array:
	var path_list := Array()
	var allow_lrc_types = SubtitleData.SupportSubtitleTypes.keys()
	FileTree.scan_folder(folder_path, func(path : String, _type : FileTree.Type):
		var suffixCheck = Utility.file_suffix(path)
		if suffixCheck in allow_lrc_types:
			path = Utility.cut_file_path(path)
			path_list.append(path)
		pass
		,false
	)
	return path_list


func _all_audio_path_list() -> Array:
	var list = %PathBindForm.all_left_paths()
	var result := Array()
	for p in list:
		result.append(_bind_path_to_relative(p))
	return result


func _auto_match_lrcs_to_audio(lrc_path_list : Array) -> Dictionary:
	var all_audio_path = _all_audio_path_list()
	#排除已经绑定对象
	for key in SuntomeGlobal.sound_subtitle_bind_info.keys():
		all_audio_path.erase(key)

	var match_result := Dictionary()
	#首先检查同文件夹下同名的对象
	for a_path in all_audio_path:
		var a_locate_path := Utility.file_locate_path(a_path)
		var a_file_name = Utility.file_name_without_suffix(a_path)
		for l_path in lrc_path_list:
			var l_locate_path := Utility.file_locate_path(l_path)
			if a_locate_path == l_locate_path:
				if a_file_name == Utility.file_name_without_suffix(l_path):
					match_result.set(a_path, l_path)

	#把已经配好的字幕文件从队列去除
	for a_path in match_result:
		var l_path = match_result[a_path]
		all_audio_path.erase(a_path)
		lrc_path_list.erase(l_path)

	#再检查同名的对象
	for a_path in all_audio_path:
		var a_file_name = Utility.file_name_without_suffix(a_path)
		for l_path in lrc_path_list:
			if a_file_name == Utility.file_name_without_suffix(l_path):
				match_result.set(a_path, l_path)

	#返回结果
	return match_result
