class_name SuntomeSerialization

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

	maindict.set("Player_Version", SuntomeGlobal.Data_Version)

	return JSON.stringify(JSON.from_native(maindict))


static var unserialize_global : suntome_global = null


#将suntome_global对象反序列化，返回错误信息，如果没有出错，返回空字符串
#函数不检查suntome_global是否是空对象，请传递一个刚new的suntome_global对象
static func unserialize(out : suntome_global, data : String) -> String:
	unserialize_global = out

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

	#再构造suntome_nodes
	#suntome_nodes需要两步构造，一步是自身对象的创建，一步是各节点之间连接的创建
	var stmnodes : Dictionary = ValueFromDictOrError(errorinfo, main_dict, "suntome_nodes")
	for uid in stmnodes:
		var dict : Dictionary = stmnodes[uid]
		var stmnode := SuntomeUnSerializeFisrt(dict, errorinfo)
		if not errorinfo.is_empty():
			push_error(errorinfo)
			return "error in suntome_nodes unserialize step1"

		out.suntome_nodes.set(uid, stmnode)

	for uid in stmnodes:
		var dict : Dictionary = stmnodes[uid]
		var node_data = dict["data"]
		var errorlist = out.suntome_nodes[uid].unserialize_second(node_data)
		if not errorlist.is_empty():
			push_error(errorlist)
			return "error in node connect: " + String.num_int64(uid)

	#最后构造begin_node和sourou_node
	var beginnodedata = ValueFromDictOrError(errorinfo, main_dict, "begin_node")
	var sourounodedata = ValueFromDictOrError(errorinfo, main_dict, "sourou_node")
	out.begin_node.unserialize_first(beginnodedata)
	out.sourou_node.unserialize_first(sourounodedata)
	out.begin_node.unserialize_second(beginnodedata)
	out.sourou_node.unserialize_second(sourounodedata)
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


static func SetValueFromDictOrError(opnion : Array, dict : Dictionary, key : String, obj : Object):
	SetIfNotNull(obj, key, ValueFromDictOrError(opnion, dict, key))


#将SuntomeNodeBase派生对象序列化的函数，该函数会标记派生对象的类型
static func SuntomeNodeSerialize(stmnode : SuntomeNodeBase) -> Dictionary:
	var result := Dictionary()
	if stmnode is SuntomeNode:
		result.set("TYPE", "TYPE_SuntomeNode")
		result.set("data", stmnode.serialize())
	elif stmnode is SuntomeParaNode:
		result.set("TYPE", "TYPE_SuntomeParaNode")
		result.set("data", stmnode.serialize())
	elif stmnode is SuntomeSelectPictNode:
		result.set("TYPE", "TYPE_SuntomeSelectPictNode")
		result.set("data", stmnode.serialize())
	else:
		push_error("stmnode 无法序列化")
	return result


#将SuntomeNodeBase派生对象反序列化的函数，该函数会判断派生对象的类型
static func SuntomeUnSerializeFisrt(dict : Dictionary, errorlist : Array) -> SuntomeNodeBase:
	if not dict.has_all(["TYPE", "data"]):
		errorlist.append("该数据对象不是suntomeNodeBase")
		return null

	var data = dict["data"]
	var type = dict["TYPE"]
	var node = null
	if "TYPE_SuntomeNode" == type:
		node = SuntomeNode.new()
	elif "TYPE_SuntomeParaNode" == type:
		node = SuntomeParaNode.new()
	elif "TYPE_SuntomeSelectPictNode" == type:
		node = SuntomeSelectPictNode.new()
	else:
		errorlist.append("不支持的数据类型: " + type)
		return

	node.unserialize_first(data)
	return node


#将SuntomeNodeBase派生对象反序列化的函数，该函数会判断派生对象的类型
static func SuntomeUnSerializeSecond(dict : Dictionary, errorlist : Array) -> SuntomeNodeBase:
	if not dict.has_all(["TYPE", "data"]):
		errorlist.append("该数据对象不是suntomeNodeBase")
		return null

	var data = dict["data"]
	var type = dict["TYPE"]
	var node = null
	if "TYPE_SuntomeNode" == type:
		node = SuntomeNode.new()
	elif "TYPE_SuntomeParaNode" == type:
		node = SuntomeNode.new()
	elif "TYPE_SuntomeSelectPictNode" == type:
		node = SuntomeNode.new()
	else:
		errorlist.append("不支持的数据类型: " + type)
		return

	node.unserialize_first(data)
	return node
