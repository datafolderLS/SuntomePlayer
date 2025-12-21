class_name SuntomeSelectPictNode extends "res://core/suntome_node_base.gd"

#节点使用的图片信息，可以为路径，也可以是SelectPicContent对象
var usedSelectPic : SelectPicContent

#本节点使用的音频对象，可以为空
var usedSoundObject : SoundObjContent = null

#选项到相连节点uid的映射，键值对类型为{button_info_name : string, uid : int}
var nextNodes_button_to_uid : Dictionary = {}

static func new_node() -> SuntomeSelectPictNode:
	var newNode := SuntomeSelectPictNode.new()
	newNode.uid = SuntomeNodeBase.random_uid()
	return newNode


func get_reversed_node_to_value_dict() -> Dictionary:
	var new_dict = Dictionary()
	for key in nextNodes_button_to_uid:
		var value = nextNodes_button_to_uid[key]
		new_dict.set(value, key)
	return new_dict


func get_unused_names():
	var allnames = usedSelectPic.buton_index.keys()
	var usednames = nextNodes_button_to_uid.keys()
	return allnames.filter(
		func(v : String): return not usednames.has(v)
	)


func remove_target_connect(target : SuntomeNodeBase):
	var removed_key = String()
	for key in nextNodes_button_to_uid:
		var value = nextNodes_button_to_uid[key]
		if value == target.uid:
			removed_key = key
			break
	nextNodes_button_to_uid.erase(removed_key)
	nextNodes.erase(target.uid)


func process_button_name_change(prename : String, now_name : String):
	if nextNodes_button_to_uid.has(prename):
		var preuid = nextNodes_button_to_uid[prename]
		nextNodes_button_to_uid[now_name] = preuid
		nextNodes_button_to_uid.erase(prename)


#序列化和反序列化的函数
func serialize() -> Dictionary:
	var dict := Dictionary()
	dict.set("usedSoundObject", 0 if null == usedSoundObject else usedSoundObject.name)
	dict.set("usedSelectPic", 0 if null == usedSelectPic else usedSelectPic.name)
	dict.set("nextNodes_button_to_uid", nextNodes_button_to_uid)

	#SuntomeNodeBase的数据存储
	dict.set("position", position)
	dict.set("uid", uid)
	dict.set("nextNodes", serialize_nextNodes_info())
	return dict


#反序列化第一步，如果没有出错就返回空列表，否则返回错误信息列表
#这一步只进行节点构建，不涉及节点的连接
func unserialize_first(dict : Dictionary, mapcbs : SuntomeSerialization.GlobalInfoMapCBs) -> Array:
	var errorinfo := Array()
	#SuntomeNodeBase的数据读取
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "position", self)
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "uid", self)

	#获取视频对象
	var soundname = SuntomeSerialization.ValueFromDictOrError(errorinfo, dict, "usedSoundObject")
	if typeof(soundname) == TYPE_STRING:
		var sobj = mapcbs.sound_obj_map_cb.call(soundname)
		if null == sobj:
			errorinfo.append("SelectPictNode未找到名称为 " + soundname + " 的音频对象")
		else:
			usedSoundObject = sobj
		# if not SuntomeSerialization.unserialize_global.sound_object_contents.has(soundname):
		# 	errorinfo.append("SelectPictNode未找到名称为 " + soundname + " 的音频对象")
		# else:
		# 	usedSoundObject = SuntomeSerialization.unserialize_global.sound_object_contents[soundname]
	else :
		usedSoundObject = null

	var selectpicname = SuntomeSerialization.ValueFromDictOrError(errorinfo, dict, "usedSelectPic")
	if typeof(selectpicname) == TYPE_STRING:
		var spicobj = mapcbs.select_pic_map_cb.call(selectpicname)
		if null == spicobj:
			errorinfo.append("SelectPictNode未找到名称为 " + selectpicname + " 的选择图片对象")
		else:
			usedSelectPic = spicobj
		# if not SuntomeSerialization.unserialize_global.select_pic_contents.has(selectpicname):
		# 	errorinfo.append("SelectPictNode未找到名称为 " + selectpicname + " 的选择图片对象")
		# else:
		# 	usedSelectPic = SuntomeSerialization.unserialize_global.select_pic_contents[selectpicname]
	else:
		usedSelectPic = null

	return errorinfo


#反序列化，如果没有出错就返回空列表，否则返回错误信息列表
#这一步进行节点的连接
func unserialize_second(dict : Dictionary, mapcbs : SuntomeSerialization.GlobalInfoMapCBs) -> Array:
	var errorinfo := Array()
	var list : Array = SuntomeSerialization.ValueFromDictOrError(errorinfo, dict, "nextNodes")
	errorinfo.append_array(unserialize_nextNodes_info(list, mapcbs))

	#对nextNodes_button_to_uid进行重映射
	var ntbtu = SuntomeSerialization.ValueFromDictOrError(errorinfo, dict, "nextNodes_button_to_uid")
	if typeof(ntbtu) == TYPE_DICTIONARY:
		for button_name in ntbtu:
			var tar_uid : int = ntbtu[button_name]
			var now_uid = mapcbs.uid_map_cb.call(tar_uid)
			if null == now_uid:
				continue
			if nextNodes.has(now_uid):
				nextNodes_button_to_uid.set(button_name, now_uid)

	return errorinfo
#end(序列化和反序列化的函数)
