#字幕数据对象
class_name SubtitleData extends RefCounted

#单句台词对象
class subtitledata extends RefCounted:
	var start_time : float = 0.0
	var end_time   : float = 0.0
	var substr     : String = String()

#内部存储的数据，数据成员为subtitledata
var _data := Array()

#如果构造失败，这里会有错误信息
var errorinfo : String = String()

static var SupportSubtitleTypes := {
	"lrc" : "_read_from_lyric_file"
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
	
	var strdata = file.get_as_text()
	Callable(data, SupportSubtitleTypes[type]).call(strdata)
	return data


func _read_from_lyric_file(str : String):
	print("read data from lrc file")

	

	pass