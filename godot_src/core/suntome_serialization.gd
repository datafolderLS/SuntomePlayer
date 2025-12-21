class_name SuntomeSerialization

#用于反序列化的函数对象集合
class GlobalInfoMapCBs extends RefCounted:
	var suntomenode_map_cb : Callable      #(uid : Int)->SuntomeNodeBase 基于uid获取指向的SuntomeNodeBase，其中uid需先经过uid_map_cb进行映射，如果指向的SuntomeNodeBase不存在返回null
	var sound_obj_map_cb : Callable        #(key : String)->SoundObjContent 基于key获取指向的SoundObjContent，如果不存在返回null
	var select_pic_map_cb : Callable       #(key : String)->SelectPicContent 基于key获取指向的SelectPicContent，如果不存在返回null
	var uid_map_cb : Callable              #(uid : Int)->int 对uid进行再映射，用于复制贴贴，如果不存在会返回null

#将suntome_global对象序列化，返回一个JSON.stringify的返回值，如果出错，返回"error"
static func serialize(gl : suntome_global) -> String:
	var sobjctts := Dictionary() #音频对象
	var slpcctts := Dictionary() #选择图片对象
	var stmnodes := Dictionary() #流程节点对象

	for name in gl.sound_object_contents:
		var sobjctt : SoundObjContent = gl.sound_object_contents[name]
		sobjctts.set(name, sobjctt.serialize())

	for name in gl.select_pic_contents:
		var slpictt : SelectPicContent = gl.select_pic_contents[name]
		slpcctts.set(name, slpictt.serialize())

	for uid in gl.suntome_nodes:
		var node = gl.suntome_nodes[uid]
		stmnodes.set(uid, SuntomeNodeSerialize(node))

	var maindict := Dictionary()
	maindict.set("sound_object_contents", sobjctts)
	maindict.set("select_pic_contents", slpcctts)

	maindict.set("suntome_nodes", stmnodes)

	maindict.set("begin_node", gl.begin_node.serialize())
	maindict.set("sourou_node", gl.sourou_node.serialize())

	#字幕文件绑定信息
	maindict.set("sound_subtitle_bind_info", gl.sound_subtitle_bind_info)

	maindict.set("Player_Version", SuntomeGlobal.Data_Version)

	return JSON.stringify(JSON.from_native(maindict))


# static var unserialize_global : suntome_global = null


#将suntome_global对象反序列化，返回错误信息，如果没有出错，返回空字符串
#函数不检查suntome_global是否是空对象，请传递一个刚new的suntome_global对象
static func unserialize(out : suntome_global, data : String) -> String:

	var json = JSON.new()
	var error = json.parse(data)
	if OK != error:
		return "JSON 解析错误：" + json.get_error_message() + " 行号 "+ String.num_int64(json.get_error_line())


	var main_dict = JSON.to_native(json.data)
	if typeof(main_dict) != TYPE_DICTIONARY:
		return "json根类型错误，不是dictionary"

	#先构造sound_object_contents和select_pic_contents
	var errorinfo := Array()
	var sobjctts : Dictionary = ValueFromDictOrError(errorinfo, main_dict, "sound_object_contents")
	var slpcctts : Dictionary = ValueFromDictOrError(errorinfo, main_dict, "select_pic_contents")

	for name : String in sobjctts:
		var sobjctt := SoundObjContent.new()
		var errorlist = sobjctt.unserialize(sobjctts[name])
		if not errorlist.is_empty():
			push_error(errorlist)
			return "error in sound_object_contents unserialize"

		out.sound_object_contents.set(sobjctt.name, sobjctt)

	for name : String in slpcctts:
		var slpictt := SelectPicContent.new()
		var errorlist = slpictt.unserialize(slpcctts[name])
		if not errorlist.is_empty():
			push_error(errorlist)
			return "error in select_pic_contents unserialize"

		out.select_pic_contents.set(slpictt.name, slpictt)

	var mapcbs := GlobalInfoMapCBs.new()
	mapcbs.suntomenode_map_cb = func(_uid : int):
		return out.suntome_nodes.get(_uid)

	mapcbs.sound_obj_map_cb = func(key : String):
		return out.sound_object_contents.get(key)

	mapcbs.select_pic_map_cb = func(key : String):
		return out.select_pic_contents.get(key)

	mapcbs.uid_map_cb = func(_uid : int): return _uid

	#再构造suntome_nodes
	#suntome_nodes需要两步构造，一步是自身对象的创建，一步是各节点之间连接的创建
	var stmnodes : Dictionary = ValueFromDictOrError(errorinfo, main_dict, "suntome_nodes")
	for uid in stmnodes:
		var dict : Dictionary = stmnodes[uid]
		var stmnode := SuntomeUnSerializeFisrt(dict, errorinfo, mapcbs)
		if not errorinfo.is_empty():
			push_error(errorinfo)

		out.suntome_nodes.set(uid, stmnode)

	for uid in stmnodes:
		var dict : Dictionary = stmnodes[uid]
		var node_data = dict["data"]
		var errorlist = out.suntome_nodes[uid].unserialize_second(node_data, mapcbs)
		if not errorlist.is_empty():
			push_error(errorlist)

	#最后构造begin_node和sourou_node
	var beginnodedata = ValueFromDictOrError(errorinfo, main_dict, "begin_node")
	var sourounodedata = ValueFromDictOrError(errorinfo, main_dict, "sourou_node")
	out.begin_node.unserialize_first(beginnodedata, mapcbs)
	out.sourou_node.unserialize_first(sourounodedata, mapcbs)
	out.begin_node.unserialize_second(beginnodedata, mapcbs)
	out.sourou_node.unserialize_second(sourounodedata, mapcbs)

	#获取字幕文件绑定信息
	var ssbi = ValueFromDictOrError(errorinfo, main_dict, "sound_subtitle_bind_info")
	if null != ssbi:
		out.sound_subtitle_bind_info = ssbi

	return ""


#工具函数，用于从dict中取出键为key的值，如果key不存在，则返回null，且opnion会append错误信息
static func ValueFromDictOrError(opnion : Array, dict : Dictionary, key : String):
	if dict.has(key):
		return dict[key]
	opnion.append("missing value key: " + key)
	return null


static func SetIfNotNull(obj : Object, key : String, value):
	var orgtype = typeof(obj.get(key))
	var vtype = typeof(value)

	if TYPE_NIL == orgtype:
		printerr("obj does not have property: ", key)
	elif TYPE_NIL == vtype:
		printerr("value is nil, key: ", key)
	elif orgtype == vtype:
		obj.set(key, value)
	elif orgtype == TYPE_INT and vtype == TYPE_FLOAT:
		obj.set(key, int(value))
	# elif TYPE_STRING == vtype:
	# 	if TYPE_VECTOR2 == orgtype:
	# 		Vector2()
	else:
		printerr("value type not correct, key: ", key)
		Utility.CriticalFail()


static func SetValueFromDictOrError(opnion : Array, dict : Dictionary, key : String, obj : Object):
	SetIfNotNull(obj, key, ValueFromDictOrError(opnion, dict, key))


static var NormalNodeTypeMap := {
	SuntomeParaNode.normal_key() : SuntomeParaNode,
	SuntomeCountCheckNode.normal_key(): SuntomeCountCheckNode,
	SuntomeTimeBeginNode.normal_key(): SuntomeTimeBeginNode,
	SuntomeTimeCheckNode.normal_key(): SuntomeTimeCheckNode,
}


#将SuntomeNodeBase派生对象序列化的函数，该函数会标记派生对象的类型
static func SuntomeNodeSerialize(stmnode : SuntomeNodeBase) -> Dictionary:
	var result := Dictionary()
	if stmnode is SuntomeNode:
		result.set("TYPE", "TYPE_SuntomeNode")
		result.set("data", stmnode.serialize())
	elif stmnode is SuntomeSelectPictNode:
		result.set("TYPE", "TYPE_SuntomeSelectPictNode")
		result.set("data", stmnode.serialize())
	# elif stmnode is SuntomeCountCheckNode:
	# 	result.set("TYPE", "TYPE_SuntomeCountCheckNode")
	# 	result.set("data", stmnode.serialize())
	# elif stmnode is SuntomeParaNode:
	# 	result.set("TYPE", "TYPE_SuntomeParaNode")
	# 	result.set("data", stmnode.serialize())
	elif stmnode.has_method("normal_key"):
		result.set("TYPE", stmnode.normal_key())
		result.set("data", stmnode.serialize())
	else:
		push_error("stmnode 无法序列化")
		Utility.CriticalFail()

	return result


#将SuntomeNodeBase派生对象反序列化的函数，该函数会判断派生对象的类型
static func SuntomeUnSerializeFisrt(dict : Dictionary, errorlist : Array, mapcbs : GlobalInfoMapCBs) -> SuntomeNodeBase:
	if not dict.has_all(["TYPE", "data"]):
		errorlist.append("该数据对象不是suntomeNodeBase")
		return null

	var data = dict["data"]
	var type = dict["TYPE"]
	var node = null
	if "TYPE_SuntomeNode" == type:
		node = SuntomeNode.new()
	elif "TYPE_SuntomeSelectPictNode" == type:
		node = SuntomeSelectPictNode.new()
	# elif "TYPE_SuntomeParaNode" == type:
	# 	node = SuntomeParaNode.new()
	# elif "TYPE_SuntomeCountCheckNode" == type:
	# 	node = SuntomeCountCheckNode.new()
	elif NormalNodeTypeMap.has(type):
		node = NormalNodeTypeMap[type].new()
	else:
		errorlist.append("不支持的数据类型: " + type)
		return

	node.unserialize_first(data, mapcbs)
	return node
