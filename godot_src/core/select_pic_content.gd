class_name SelectPicContent extends RefCounted

#图片选择对象，用于用户在界面选择选项的图片对象，允许创作者选择图片并添加按钮
#玩家点击按钮后会周转到按钮指向的节点处
#SelectPicContent将作为SuntomeNode的成员
var name : String                       #该对象的名称

var usedTexturePath : String = "" :
	set(_value):
		usedTexturePath = _value
		texture_change_sig.emit(self)

#选项到相连节点uid的映射，键值对类型为{button_info_name : string, uid : int}
var nextNodes_button_to_uid : Dictionary = {}

#button_index : string到SelectButtonInfo对象的键值对{button_info_name : string, info : SelectButtonInfo}
var buton_index : Dictionary = {}

class SelectButtonInfo:
	var pos          : Vector2   #相对图片的位置
	var size         : Vector2   #相对图片的大小
	var bgcolor      : Color     #背景颜色
	var name         : String    #按钮名称，该值在同组图片下唯一
	var name_as_text : bool      #text是否和name相同，如果为true，无视text
	var text         : String    #按钮文字
	var fontcolor    : Color     #字体颜色
	var isPicture    : bool      #标记使用图片来作为按钮
	var picpath      : String    #图片路径，如果isPicture为true使用该路径对象

var before_delete_cb : Callable         #当用户删除该对象时，触发该函数对象
var name_change_cb : Callable         #当用户修改名称时，触发该函数对象


signal name_changed_sig(node : SelectPicContent)
signal before_delete_sig(node : SelectPicContent)
signal texture_change_sig(node : SelectPicContent)

#用户修改选项按钮的name时触发(该信号仅由Select_pic_editor触发
signal button_name_change_signal(prename : String, now_name : String)
#用户删除选项按钮时触发信号
signal button_before_delete_signal(name : String)


func before_delete():
	if before_delete_cb.is_valid():
		before_delete_cb.call(self)

	before_delete_sig.emit(self)


func change_name(new_name : String):
	name = new_name
	if name_change_cb.is_valid():
		name_change_cb.call(self)

	name_changed_sig.emit(self)


#修改button的名称
func update_button_index_key(prekey : String, newkey : String):
	if prekey == newkey:
		return

	var preinfo = buton_index[prekey]
	buton_index[newkey] = preinfo
	buton_index.erase(prekey)

	if nextNodes_button_to_uid.has(prekey):
		var preuid = nextNodes_button_to_uid[prekey]
		nextNodes_button_to_uid[newkey] = preuid
		nextNodes_button_to_uid.erase(prekey)


func delete_button_info(key : String):
	button_before_delete_signal.emit(key)
	buton_index.erase(key)
	nextNodes_button_to_uid.erase(key)
	pass


func get_unused_names():
	var allnames = buton_index.keys()
	var usednames = nextNodes_button_to_uid.keys()
	return allnames.filter(
		func(v : String): return not usednames.has(v)
	)


func get_reversed_node_to_value_dict() -> Dictionary:
	var new_dict = Dictionary()
	for key in nextNodes_button_to_uid:
		var value = nextNodes_button_to_uid[key]
		new_dict.set(value, key)
	return new_dict


func remove_uid(uid : int):
	var removed_key = String()
	for key in nextNodes_button_to_uid:
		var value = nextNodes_button_to_uid[key]
		if value == uid:
			removed_key = key
			break
	nextNodes_button_to_uid.erase(removed_key)


#序列化和反序列化的函数
func serialize() -> Dictionary:
	var dict := Dictionary()
	dict.set("name", name)
	dict.set("usedTexturePath", usedTexturePath)
	dict.set("nextNodes_button_to_uid", nextNodes_button_to_uid)
	var snode := Array()
	for key in buton_index:
		var info : SelectButtonInfo = buton_index[key]
		var sdic := Dictionary()
		sdic.set("pos", info.pos)
		sdic.set("size", info.size)
		sdic.set("bgcolor", info.bgcolor)
		sdic.set("name", info.name)
		sdic.set("name_as_text", info.name_as_text)
		sdic.set("text", info.text)
		sdic.set("fontcolor", info.fontcolor)
		sdic.set("isPicture", info.isPicture)
		sdic.set("picpath", info.picpath)
		snode.append(sdic)

	dict.set("buton_index", snode)
	return dict


#反序列化，如果没有出错就返回空列表，否则返回错误信息列表
func unserialize(dict : Dictionary) -> Array:
	var errorinfo := Array()
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "name", self)
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "usedTexturePath", self)
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "nextNodes_button_to_uid", self)
	buton_index.clear()
	var snode = SuntomeSerialization.ValueFromDictOrError(errorinfo, dict, "buton_index")
	if null != snode:
		for sdic : Dictionary in snode:
			var info = SelectButtonInfo.new()
			SuntomeSerialization.SetValueFromDictOrError(errorinfo, sdic, "pos", info)
			SuntomeSerialization.SetValueFromDictOrError(errorinfo, sdic, "size", info)
			SuntomeSerialization.SetValueFromDictOrError(errorinfo, sdic, "bgcolor", info)
			SuntomeSerialization.SetValueFromDictOrError(errorinfo, sdic, "name", info)
			SuntomeSerialization.SetValueFromDictOrError(errorinfo, sdic, "name_as_text", info)
			SuntomeSerialization.SetValueFromDictOrError(errorinfo, sdic, "text", info)
			SuntomeSerialization.SetValueFromDictOrError(errorinfo, sdic, "fontcolor", info)
			SuntomeSerialization.SetValueFromDictOrError(errorinfo, sdic, "isPicture", info)
			SuntomeSerialization.SetValueFromDictOrError(errorinfo, sdic, "picpath", info)
			buton_index.set(info.name, info)

	return errorinfo
#end(序列化和反序列化的函数)