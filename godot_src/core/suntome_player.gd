extends Node

#suntome_player是寸止播放核心，控制图片的切换以及音频的播放

#播放对象，用于切换音频和图片
var _player : Player
var _cur_play_node : SuntomeNodeBase

#button_cache存储过程中创建的按钮
var button_cache : Array = Array()

#每一帧都会检查该对象，然后播放
var _next_node : SuntomeNodeBase = null

#suntome_node切换时触发信号，suntome_node为新的节点
signal suntome_node_change(suntome_node : SuntomeNodeBase)

#步进函数
var _step_func := Callable()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# if _delay_call_func.is_valid():
	# 	_recursion_check = 0 #清空栈溢出计数
	# 	_delay_call_func.call_deferred()
	# 	_delay_call_func = Callable()
	if null != _next_node:
		var temp = _next_node
		_next_node = null
		# print("play node, pos: ", temp.position)
		select_node_play_mode(temp)
	pass


#设置图像播放器
func set_player(player : Player):
	_player = player
	_player.play_finished.connect(_sound_play_over)
	pass


#从suntome_node开始播放寸止对象
func start_from_node(suntome_node : SuntomeNodeBase):
	_play_node_in_next_frame(suntome_node)
	pass


#暂停播放
func pause_play():
	pass

#步进播放
func step_in_next():
	if _step_func.is_valid():
		_step_func.call()
	pass


#基于节点类型使用不同的播放方式
func select_node_play_mode(suntome_node : SuntomeNodeBase):
	_cur_play_node = suntome_node
	suntome_node_change.emit(_cur_play_node)
	_step_func = Callable()

	if suntome_node is SuntomeSelectPictNode:
		play_select_pic_node(_cur_play_node)
	elif suntome_node is SuntomeNode:
		play_suntome_node(suntome_node)
	# elif suntome_node is SuntomeParaNode:
	# 	play_normal_node(suntome_node)
	# elif suntome_node is SuntomeCountCheckNode:
	# 	play_normal_node(suntome_node)
	else:
		play_normal_node(suntome_node)
		# Utility.CriticalFail()


#播放普通节点
func play_suntome_node(suntome_node : SuntomeNode):
	if suntome_node.is_suntome:
		SuntomeGlobal.suntome_count += 1

	if suntome_node.is_transit_node:
		var next_node = suntome_node.get_next_node()
		_play_node_in_next_frame(next_node)
		return

	if null == suntome_node.usedSoundObject:
		printerr("没有音频对象")
		SuntomeGlobal.ErrorOccur("soundobjnotbind", suntome_node)
		return

	if suntome_node.usedTexturePath.is_empty():
		printerr("没有图片对象")
		SuntomeGlobal.ErrorOccur("texturenotbind", suntome_node)
		return

	var playobj = Player.NextPlayerObj.new()

	playobj.nextTexture = TextureCenter.get_picture(suntome_node.usedTexturePath)
	var sound_path = suntome_node.usedSoundObject.get_next_sound()
	playobj.nextSound = Utility.load_supported_audio(sound_path)

	#检查是否有字幕文件来播放
	playobj.sound_subtitle = _load_sub_data_if_exist(sound_path)

	_player.play_next(playobj)

	_step_func = func(): _sound_play_over(null)
	pass


#播放图片选择节点
func play_select_pic_node(suntome_node : SuntomeSelectPictNode):
	var selectObj = Player.NextSelectPicObj.new()
	if null != suntome_node.usedSoundObject:
		selectObj.getNextSoundAndSub = func():
			var soundpath = suntome_node.usedSoundObject.get_next_sound()
			var sound = Utility.load_supported_audio(soundpath)
			return [sound, _load_sub_data_if_exist(soundpath)]
	else:
		selectObj.getNextSoundAndSub = func(): return [null, null]

	var selectpicobj = suntome_node.usedSelectPic
	var path = selectpicobj.usedTexturePath
	selectObj.nextTexture = TextureCenter.get_picture(path)
	selectObj.emitAllButton = func(picture : TextureRect):
		for bname in selectpicobj.buton_index:
			var info = selectpicobj.buton_index[bname]
			var addone = SimpleButton.create_button_from_button_info(picture, info)

			button_cache.append(addone)

			addone.pressed.connect(
				func(_button : SimpleButton):
					if not selectpicobj.nextNodes_button_to_uid.has(bname):
						printerr("该按键没有绑定传递对象 ", bname)
						return
					var uid = selectpicobj.nextNodes_button_to_uid[bname]
					var nextNode = suntome_node.nextNodes[uid]

					#清空所有button
					# for b : SimpleButton in button_cache:
					# 	picture.remove_child(b)
					# 	b.queue_free()
					# button_cache.clear()
					_clear_button_cache()
					_play_node_in_next_frame(nextNode)
					pass
			)
		pass

	_player.play_select_pic(selectObj)
	pass


# func play_para_setting_node(suntome_node : SuntomeParaNode):
# 	suntome_node.do_operation()
# 	var next = suntome_node.next_node()
# 	if null == next:
# 		return
# 	_play_node_in_next_frame(next)


# func play_count_check_node(suntome_node : SuntomeCountCheckNode):
# 	var next = suntome_node.next_node()
# 	if null == next:
# 		return
# 	_play_node_in_next_frame(next)
# 	pass


func play_normal_node(suntome_node : SuntomeNodeBase):
	if suntome_node.has_method("do_operation"):
		suntome_node.do_operation()

	var next = suntome_node.next_node()
	if null == next:
		return
	_play_node_in_next_frame(next)


func _play_node_in_next_frame(suntome_node : SuntomeNodeBase):
	_clear_button_cache()
	_next_node = suntome_node


#当前正在播放的SuntomeNode
func current_play_node() -> SuntomeNodeBase:
	return _cur_play_node


func _sound_play_over(_obj : Player.NextPlayerObj):
	print("play next")
	var next = _cur_play_node.get_next_node()

	if null == next:
		print("play over")
		return

	_play_node_in_next_frame(next)
	pass


#没有寸止成功时调用函数
func omorashi_shita():
	start_from_node(SuntomeGlobal.sourou_node)


#检查sound_path的音频是否有绑定的字幕对象，如果没有或者读取出错就返回null，否则返回SubtitleData对象
func _load_sub_data_if_exist(sound_path : String) -> SubtitleData:
	var subpath : String = SuntomeGlobal.sound_subtitle_bind_info.get(Utility.cut_file_path(sound_path), "")
	if not subpath.is_empty():
		var data = SubtitleData.construct_from_file(subpath)
		if data.errorinfo.is_empty():
			return data

	return null


func _clear_button_cache():
	#清空所有button
	for b : SimpleButton in button_cache:
		b.get_parent().remove_child(b)
		b.queue_free()
	button_cache.clear()

