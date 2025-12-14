#字幕数据对象
class_name SubtitleData extends RefCounted

#单句台词对象
class lyrics extends RefCounted:
	var start_time : float = 0.0         #开始时间，单位为秒
	var end_time   : float = 0.0		 #结束时间，单位为秒
	var substr     : String = String()   

#内部存储的数据，数据成员为lyrics，且已按start_time进行排序
var _data := Array()

#如果构造失败，这里会有错误信息
var errorinfo : String = String()

static var SupportSubtitleTypes := {
	"lrc" : LrcStrImport,
	"vtt" : VttStrImport
}

static func construct_from_file(path : String) -> SubtitleData:
	var data = SubtitleData.new()
	var suffixCheck = path.rsplit(".", true, 1)
	var type = suffixCheck[1].to_lower()

	if not SupportSubtitleTypes.has(type):
		data.errorinfo = "path data type not support"
		return data
	
	var file = FileAccess.open(Utility.relative_to_full(path), FileAccess.READ)
	if null == file:
		data.errorinfo = "can not open file: " + path +" error code: " + String.num_int64(FileAccess.get_open_error())
		return data
	
	var strdata = file.get_as_text(true)
	var rel = SupportSubtitleTypes[type].new().construct_lyrics_array_from_str(strdata)
	if rel.size() > 0:
		if typeof(rel[0]) == TYPE_STRING:
			data.errorinfo = rel[0]
			return data
	
	data._data = rel
	return data


#返回time秒时显示的台词
func lyric_in_pos(time : float) -> String:
	for lyric : lyrics in _data:
		if lyric.start_time <= time and lyric.end_time >= time:
			return lyric.substr
	
	return ""