extends MarginContainer

#播放控件请求修改音频正在播放的进度时间
signal req_time_change(time : float)
#播放控件请求修改音频播放状态（播放、暂停）
signal req_play_state_change(playing : bool)

var cur_sound_total_time : float = 0.0
var cur_play_state : bool = false
var is_draging : bool = false

static var play_icon = preload("res://editor/icon/play.png")
static var pause_icon = preload("res://editor/icon/pause.png")


func _ready() -> void:
	%Button.pressed.connect(
		func():
			is_draging = false
			cur_play_state = not cur_play_state
			change_play_state_without_signal(cur_play_state)
			req_play_state_change.emit(cur_play_state)
	)

	%slider_progress.drag_started.connect(
		func():
			is_draging = true
			pass
	)

	%slider_progress.drag_ended.connect(
		func(value_changed : bool):
			if value_changed:
				var cur_value = %slider_progress.value / %slider_progress.max_value * cur_sound_total_time
				req_time_change.emit(cur_value)
	)
	pass


func change_play_state_without_signal(playing : bool):
	cur_play_state = playing
	%Button.icon = pause_icon if cur_play_state else play_icon
	pass


func update_audio_time(cur_pos : float, total : float):
	cur_sound_total_time = total
	_update_lb(cur_pos, total)
	if not is_draging:
		%slider_progress.value = cur_pos / total * %slider_progress.max_value


func _update_lb(cur_pos : float, total : float):
	%lb_progress.text = _timef(cur_pos) + "/" + _timef(total)


func _timef(time : float) -> String:
	const time_format = "%d:%d"
	const time_format_min10 = "%d:0%d"
	var minute = floor(time / 60.0)
	var second = floor(fmod(time, 60.0))
	if second < 10:
		return time_format_min10 % [minute, second]
	return time_format % [minute, second]
