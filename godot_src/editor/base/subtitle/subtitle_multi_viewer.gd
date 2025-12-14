class_name SubtitleMultiViewer extends Control

#控件用于获取当前时间()->float
var get_now_time : Callable = Callable()

var now_sub_data : SubtitleData = null
@onready var container : BoxContainer = %lyrics_label_container

#label对象到指向台词的index的映射
var index_to_label : Dictionary = Dictionary()
var curlabel : Label = null

func set_subtitledata(data : SubtitleData):
	now_sub_data = data
	var lbs = container.get_children()
	index_to_label.clear()
	curlabel = null

	for lb in lbs:
		container.remove_child(lb)
		lb.queue_free()

	if null == now_sub_data:
		return

	var subdatalist = now_sub_data._data
	for i in range(subdatalist.size()):
		var lyric : SubtitleData.lyrics = subdatalist.get(i)
		var lb = preload("res://editor/base/subtitle/lable_custom.tscn").instantiate()
		lb.text = lyric.substr
		index_to_label.set(i, lb)
		container.add_child(lb)
	pass


func _process(_delta: float) -> void:
	if null == now_sub_data:
		return
	if not get_now_time.is_valid():
		return
	if now_sub_data._data.is_empty():
		return

	#当前时间
	var n_time = clampf(get_now_time.call(), 0, 1000 * 3600)
	var subdatalist = now_sub_data._data
	var tar_lyrics_pos = subdatalist.size()
	var begindiff : bool = false

	for i in range(subdatalist.size()):
		var lyric : SubtitleData.lyrics = subdatalist.get(i)
		if n_time < lyric.start_time:
			tar_lyrics_pos = i
			begindiff = true
			break

		if lyric.start_time <= n_time and lyric.end_time >= n_time:
			tar_lyrics_pos = i
			break

	var lb = index_to_label.get(tar_lyrics_pos)

	if null != curlabel:
		curlabel.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.635))

	if null == lb:
		container.position.y = -container.size.y + size.y * 0.5
	else:
		if begindiff:
			container.position.y = -lb.position.y + size.y * 0.5 + lb.size.y * 0.5
		if not begindiff:
			container.position.y = -lb.position.y + size.y * 0.5
			curlabel = lb
			curlabel.add_theme_color_override("font_color", Color.WHITE)


# func _get_str_in_pos(index : int, data : SubtitleData) -> String:
# 	var subdatalist = data._data
# 	var sub = subdatalist.get(index)
# 	if null == sub:
# 		return ""

# 	return sub.substr



# func _set_sub_string(index : int, sstr : String):
# 	if index < -2 or index > 2:
# 		return
# 	var istr = String.num_int64(index)
# 	get_node("%sub"+ istr).text = sstr


# func _set_sub_data(strs : Array):
# 	strs.resize(5)
# 	var cnum = -2
# 	for sstr in strs:
# 		_set_sub_string(cnum, "" if sstr == null else sstr)
# 		cnum += 1
# 	pass
