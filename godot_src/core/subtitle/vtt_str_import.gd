class_name VttStrImport extends RefCounted

var x_data_in_lines : Array
var x_data_line_lenth : int = 0
var x_error_info : String
var x_error_line : int = -1
#存储处理过程中生成的SubtitleData.lyrics对象
var x_result_data := Array()

#接口函数，从str中构造SubtitleData.lyrics对象列表，如果失败返回包含错误字符串的对象
func construct_lyrics_array_from_str(data : String) -> Array:
	x_data_in_lines = data.split("\n")

	x_data_line_lenth = x_data_in_lines.size()
	var index = _process_begin_WEBVTT_line(0)

	while index < x_data_line_lenth:
		var cur_line = x_data_in_lines[index]
		if cur_line.is_empty():
			index += 1
			continue

		if cur_line.begins_with("STYLE"):
			index = _process_begin_STYLE_line(index)
			if index < 0: return _error_result(x_error_info, x_error_line)

		elif cur_line.begins_with("NOTE"):
			index = _process_begin_NOTE_line(index)
			if index < 0: return _error_result(x_error_info, x_error_line)

		else:
			break
		pass

	#文档头部已经过滤了，此时index正指向第一个cue对象开头
	while index < x_data_line_lenth:
		var cur_line = x_data_in_lines[index]
		if cur_line.is_empty():
			index += 1
			continue

		if cur_line.begins_with("STYLE"):
			x_error_info = "在cue后面定义了STYLE对象是非法的"
			x_error_line = index
			return _error_result(x_error_info, x_error_line)

		elif cur_line.begins_with("NOTE"):
			index = _process_begin_NOTE_line(index)
		else:
			index = _process_cue_line(index)
			if index < 0: return _error_result(x_error_info, x_error_line)

	#对x_result_data的数据进行排序
	x_result_data.sort_custom(func(left : SubtitleData.lyrics, right : SubtitleData.lyrics):
		return left.start_time < right.start_time
	)

	return x_result_data


func _process_begin_WEBVTT_line(line_start_index : int) -> int:
	for i in range(line_start_index, x_data_line_lenth):
		var cur_line = x_data_in_lines[i]
		if cur_line.is_empty():
			return i

	return x_data_line_lenth


func _at_end(line : int) -> bool:
	return x_data_line_lenth <= line


func _error_result(info : String, line : int) -> Array:
	var rel = "error in line: {0}, {1}".format([line, info])
	return [rel]


func _process_begin_STYLE_line(line_start_index : int) -> int:
	var index = line_start_index
	while index < x_data_line_lenth:
		var cur_line : String = x_data_in_lines[index]
		if cur_line.contains("{"):
			x_error_line = index
			while index < x_data_line_lenth:
				index += 1
				cur_line = x_data_in_lines[index]
				if cur_line.contains("}"):
					break
			if _at_end(index):
				x_error_info = "STYLE 结构体错误，没有找到}结束符"
				return -1
			break

		else: #这一行没有包含{就进入下一行
			index += 1

	if _at_end(index):
		x_error_info = "STYLE 结构体错误，没有找到{}数据块"
		x_error_line = line_start_index
		return -1

	for i in range(index, x_data_line_lenth):
		var cur_line = x_data_in_lines[i]
		if cur_line.is_empty():
			return i

	return x_data_line_lenth


func _process_begin_NOTE_line(line_start_index : int) -> int:
	for i in range(line_start_index, x_data_line_lenth):
		var cur_line = x_data_in_lines[i]
		if cur_line.is_empty():
			return i

	return x_data_line_lenth


func _process_cue_line(line_start_index : int) -> int:
	var index = line_start_index
	var cur_line : String = x_data_in_lines[index]
	if not cur_line.contains("-->"):
		index += 1

	cur_line = x_data_in_lines[index]
	if not cur_line.contains("-->"):
		x_error_info = "cue标识符只能有一行，且不能有空行"
		x_error_line = index
		return -1

	var data = SubtitleData.lyrics.new()
	var timestamp = _get_time_stamp_info(cur_line)
	if timestamp.size() < 2:
		x_error_info = timestamp[0]
		x_error_line = index
		return -1

	data.start_time = timestamp[0]
	data.end_time = timestamp[1]

	index += 1
	var bindex = index
	var eindex = bindex
	while index < x_data_line_lenth:
		cur_line = x_data_in_lines[index]
		if cur_line.is_empty():
			eindex = index
			break
		index +=1

	if _at_end(index):
		eindex = index

	var strdata = "\n".join(x_data_in_lines.slice(bindex, eindex))
	strdata = _remove_all_tag(strdata)
	if strdata.is_empty():
		x_error_info = "标签tag非法，未找到 > 结束块，行数{0}到{1}".format([bindex, eindex-1])
		x_error_line = bindex
		return -1

	strdata = strdata.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">").replace("&nbsp;", " ").replace("&lrm;", "").replace("&rlm;", "")
	data.substr = strdata
	x_result_data.append(data)
	return index


func _get_time_stamp_info(sentence : String) -> Array:
	var parts = sentence.split(" ", false)
	var begin = parts[0]
	var end = parts[2]
	var btime = Utility.timestamp_to_seconds(begin)
	var etime = Utility.timestamp_to_seconds(end)

	if btime > etime:
		return ["时间戳不合法，开始时间晚于结束时间"]

	return [btime, etime]


#删除sentence中所有<>包含的字段，并返回，如果失败返回空字符串
func _remove_all_tag(sentence : String) -> String:
	var parts = sentence.split("<")
	var rejoin := Array()
	rejoin.append(parts.get(0))
	parts.remove_at(0)

	for st in parts:
		var sindex := st.find(">")
		if sindex < 0:
			return ""
		st = st.erase(0, sindex)
		rejoin.append(st)

	return "".join(rejoin)
