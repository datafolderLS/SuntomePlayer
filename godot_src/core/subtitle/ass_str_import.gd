class_name AssStrImport extends RefCounted

#接口函数，从str中构造SubtitleData.lyrics对象列表，如果失败返回包含错误字符串的对象
func construct_lyrics_array_from_str(data : String) -> Array:
	return []