class_name LrcStrImport extends RefCounted

enum PartType {
	Nothing,   #不需要关系的信息
	Offset,    #offset设置值
	TimeStamp, #时间戳
}


#接口函数，从str中构造SubtitleData.lyrics对象列表，如果失败返回包含错误字符串的对象
func construct_lyrics_array_from_str(data : String) -> Array:
	var result = Array()

	var list = data.split("\n")

	var time_offset = 0.0

	for sentence in list:
		var type : PartType = get_sentence_type(sentence)
		# print([sentence, type])
		match type:
			PartType.Offset:
				# print(get_offset(sentence))
				time_offset = get_offset(sentence)
				pass
			PartType.TimeStamp:
				var lyrics = construct_lyrics_from_sentence(sentence)
				for dd in lyrics:
					dd.start_time += time_offset
					dd.end_time += time_offset
				result.append_array(lyrics)
				pass

	result.sort_custom(func(left : SubtitleData.lyrics, right : SubtitleData.lyrics):
		return left.start_time < right.start_time
	)

	for index in range(result.size() - 1):
		result[index].end_time = result[index + 1].start_time

	result[result.size() - 1].end_time = 1.79769e30

	return result


#判断下标在left和right之间的括号包起来的字符串的类型
func get_sentence_type(sentence : String) -> PartType:
	if not sentence.begins_with("["):
		return PartType.Nothing

	if sentence.ends_with("]"):
		var index = sentence.findn("offset:")
		if index == 1:
			return PartType.Offset
		return PartType.Nothing
	else:
		return PartType.TimeStamp


func get_offset(sentence : String) -> float:
	var index = sentence.findn(":") + 1
	var end = sentence.findn("]")
	var time_diff = sentence.substr(index , end - index)
	return time_diff.to_float() / 1000.0


#从sentence中构建字幕对象，考虑到可能有[01:30.86][01:37.24][03:20.91]xxx这样的内容，所以返回列表
func construct_lyrics_from_sentence(sentence : String) -> Array:
	# var sstart = sentence.rfindn("]") + 1
	var ctts = sentence.rsplit("]", true, 1)
	var lyric = ctts[1]

	var timestamps = ctts[0].erase(0, 1)
	var all_timestamp = timestamps.split("][")

	# print(lyric, all_timestamp)

	var result = []

	for time in all_timestamp:
		var data = SubtitleData.lyrics.new()
		data.substr = lyric
		# data.start_time = timestamp_to_seconds(time)
		data.start_time = Utility.timestamp_to_seconds(time)
		data.end_time = data.start_time
		result.append(data)
		pass

	return result


# #将03:20.91这样格式的字符串转为秒数
# func timestamp_to_seconds(stamp : String) -> float:
# 	var times = stamp.split(":")
# 	var minute = times[0].to_float()
# 	var seconds = times[1].to_float()
# 	return minute * 60.0 + seconds


func Error(info : String) -> Array:
	return [info]