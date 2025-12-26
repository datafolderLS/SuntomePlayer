class_name Player extends PanelContainer

@onready var tex1 = get_node("Texture1")
@onready var tex2 = get_node("Texture2")
@onready var sound_player : AudioStreamPlayer = get_node("AudioStreamPlayer")

#音频播放结束时触发该信号，obj为结束播放的播放对象，用户手动执行的结束不会触发该信号
signal play_finished(obj : NextPlayerObj)

var now_tex : TextureRect = null
var next_tex : TextureRect = null

class NextPlayerObj extends RefCounted:
	var nextTexture : Texture2D
	var nextSound : AudioStream
	var sound_subtitle : SubtitleData   #音频字幕数据，如果为空，就是没有字幕

class NextSelectPicObj extends RefCounted:
	var nextTexture : Texture2D
	var getNextSoundAndSub : Callable    #当音频播放完成时，重复调用该函数来获取下一个音频文件和字幕文件[stream, SubtitleData]，返回[null, ..]就不播放
	var emitAllButton : Callable   #初始化时调用该函数来初始化选择控件，调用函数传递keep_ratio_picture对象

# var waiting_next : NextPlayerObj = null
# var waiting_next_select : NextSelectPicObj = null
var fade_func : Callable = Callable()
@export var fade_time : float = 1.0

var cur_next : NextPlayerObj = null
var _play_end_func : Callable
var _fade_over_func : Callable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	now_tex = tex1
	next_tex = tex2
	sound_player.finished.connect(_finished)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if fade_func.is_valid() :
		var result = fade_func.call(delta)
		if false == result:
			return
		else :
			fade_func = Callable()

			if _fade_over_func.is_valid():
				_fade_over_func.call()

			var temp = next_tex
			next_tex = now_tex
			now_tex = temp
			sort_tex()


	pass

#将now_tex过渡到next_tex
func _fadeNextImage(delta : float) -> bool:
	var nowAlpha = now_tex.modulate.a
	next_tex.modulate.a = 1.0

	if fade_time < 0.0001:
		nowAlpha = 0.0
		pass
	else:
		nowAlpha -= delta * 1.0 / fade_time

	if nowAlpha <= 0.0:
		now_tex.modulate.a = 0.0
		return true
	else:
		now_tex.modulate.a = nowAlpha
	return false


#将now_tex过渡到next_tex
func _fadeNextImage_both(delta : float) -> bool:
	var nowAlpha = now_tex.modulate.a
	next_tex.modulate.a = 0.0

	if fade_time < 0.0001:
		nowAlpha = 0.0
		pass
	else:
		nowAlpha -= delta * 1.0 / fade_time

	if nowAlpha <= 0.0:
		now_tex.modulate.a = 0.0
		next_tex.modulate.a = 1.0
		return true
	else:
		now_tex.modulate.a = nowAlpha
		next_tex.modulate.a = 1.0 - nowAlpha
	return false


func pause():
	sound_player.set_stream_paused(true)


func _no_pic_now() -> bool:
	return now_tex.texture == null


func play_next(waiting_next : NextPlayerObj) -> void:
	next_tex.texture = waiting_next.nextTexture
	sound_player.set_block_signals(true)
	sound_player.stop()
	sound_player.set_stream(waiting_next.nextSound)
	sound_player.set_block_signals(false)
	cur_next = waiting_next
	if _no_pic_now():
		fade_func = Callable(self, "_fadeNextImage_both")
	else:
		fade_func = Callable(self, "_fadeNextImage")

	_fade_over_func = func() : sound_player.play()

	_play_end_func = func():
		play_finished.emit(cur_next)

	#设置字幕文件，如果是null就不播放字幕了
	set_subtitle(waiting_next.sound_subtitle)
	waiting_next = null
	pass


func play_select_pic(next : NextSelectPicObj):
	next_tex.texture = next.nextTexture
	sound_player.set_block_signals(true)
	sound_player.stop()

	var nextsoundAndSub = next.getNextSoundAndSub.call()

	if null != nextsoundAndSub[0]:
		sound_player.set_stream(nextsoundAndSub[0])
		set_subtitle(nextsoundAndSub[1])

		_play_end_func = func():
			sound_player.set_block_signals(true)
			sound_player.stop()
			var next_sound_sub = next.getNextSoundAndSub.call()
			sound_player.set_stream(next_sound_sub[0])
			sound_player.play()
			sound_player.set_block_signals(false)
			set_subtitle(next_sound_sub[1])
	else:
		_play_end_func = Callable()

	sound_player.set_block_signals(false)
	# next.emitAllButton.call(next_tex)
	_fade_over_func = func():
		if null != nextsoundAndSub[0]:
			sound_player.play()
		next.emitAllButton.call(next_tex)

	if _no_pic_now():
		fade_func = Callable(self, "_fadeNextImage_both")
	else:
		fade_func = Callable(self, "_fadeNextImage")
	pass


#图片和图片之间的过渡时间，输入会被自动限制到[0, max_float)上
func set_fade_time(time : float):
	fade_time = time if time >=0 else 0.0
	pass


#将now_tex放到前面，next_tex放到后面
func sort_tex():
	move_child(now_tex, 2)
	move_child(next_tex, 1)
	pass


func get_progress() -> float :
	return sound_player.get_playback_position()


func get_total_lenth() -> float :
	if null == sound_player.get_stream() :
		return 0.0
	return sound_player.get_stream().get_length()


func _finished():
	if _play_end_func.is_valid():
		_play_end_func.call()
	pass


func stop():
	sound_player.stop()


func set_subtitle(data : SubtitleData):
	if null == data:
		%SubtitleViewer.get_now_subtitle = Callable()
		return

	%SubtitleViewer.get_now_subtitle = func():
		if sound_player.is_playing():
			var pos = sound_player.get_playback_position()
			var strr = data.lyric_in_pos(pos)
			return strr
		return ""
