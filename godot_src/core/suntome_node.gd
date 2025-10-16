#播放节点，包含显示的图片信息和使用到的音频对象
class_name SuntomeNode extends "res://core/suntome_node_base.gd"

#节点使用的图片路径
var usedTexturePath : String = String()

#本节点使用的音频对象
var usedSoundObject : SoundObjContent = null

#相连节点uid到概率的映射，键值对类型为{uid : int, value(float, String)}
#其中值类型可能为float可能为String，当为String时表示变量的值
var nextNodes_chance : Dictionary = {}

#相连节点uid到次序的映射，键值对类型为{uid : int, index : int}
var nextNodes_index : Dictionary = {}

#该节点使用的播放方式，分为顺序、随机不重复、随机
var play_mode : Utility.RandomHelper.Method

#是否为过渡节点
var is_transit_node : bool = false

#标记该点是否是寸止计数点，当播放遍历到该点时会将寸止计数+1
var is_suntome : bool = false

#辅助变量，不保存
var _last_trans_node_uid : int
var _transed_nodes_uids : Array = Array()


static func new_node() -> SuntomeNode:
	var newNode := SuntomeNode.new()
	newNode.uid = SuntomeNodeBase.random_uid()
	newNode.play_mode = Utility.RandomHelper.Method.RandomNoRepeat
	newNode.position = Vector2(50,50)
	return newNode


static func new_transit_node() -> SuntomeNode:
	var newNode := SuntomeNode.new_node()
	newNode.is_transit_node = true
	return newNode


#检查nextNodes_chance和nextNodes_index数据是否有效并更新
func check_chance_index_data():
	if nextNodes.is_empty():
		nextNodes_chance.clear()
		nextNodes_index.clear()
		return

	#获取当前相连的节点uid
	var uidkeys = nextNodes.keys()

	#检查nextNodes_chance数组是否完备，和nextNodes中的数据是否有冲突
	if nextNodes_chance.keys() != uidkeys:
		var removeKeys = nextNodes_chance.keys().filter(func(v : int) : return not uidkeys.has(v))
		for _uid in removeKeys:
			nextNodes_chance.erase(_uid)

		#检测uidkeys中不包含在nextNodes_chance中的uid
		var appendKey = uidkeys.duplicate()
		for _uid in nextNodes_chance:
			appendKey.erase(_uid)

		var average = 1.0 / appendKey.size()
		for _uid in appendKey:
			nextNodes_chance.set(_uid, average)

	#检查nextNodes_index数组是否完备，和nextNodes中的数据是否有冲突
	if nextNodes_index.keys() != uidkeys:
		var indexAllow = range(1, uidkeys.size() + 1)
		var need_remove : Array
		for _uid in nextNodes_index:
			if uidkeys.has(_uid):
				var i = nextNodes_index[_uid]
				indexAllow.erase(i)
			else :
				need_remove.append(_uid)

		for _uid in need_remove:
			nextNodes_index.erase(_uid)

		for _uid in uidkeys:
			if not nextNodes_index.has(_uid):
				var i = indexAllow.pop_back()
				nextNodes_index.set(_uid, i)
	pass


#将nextNodes_index按照1到size()进行填充
func update_index_data():
	var reserveMap = Dictionary()
	for _uid in nextNodes_index:
		reserveMap.set(nextNodes_index[_uid], _uid)

	var indexall = reserveMap.keys()
	indexall.sort()

	for i in range(indexall.size()):
		var curIndex = indexall.get(i)
		var _uid = reserveMap[curIndex]
		nextNodes_index[_uid] = i + 1

	pass


#基于play_mode来获取下一个节点并返回，
#如果返回null就说明没有下一个节点，这是结束节点
func get_next_node() -> SuntomeNodeBase:
	if nextNodes.is_empty():
		return null

	if nextNodes.size() == 1:
		_last_trans_node_uid = nextNodes.keys().get(0)
		_transed_nodes_uids.append(_last_trans_node_uid)
		return nextNodes.get(_last_trans_node_uid)
	# if null == rand_helper:
	# 	update_rand_helper()

	# if play_mode != rand_helper.method_type:
	# 	rand_helper.change_method_type(play_mode)

	match play_mode:
		Utility.RandomHelper.Method.Sequence:
			# print_debug("顺序播放还没有实现")
			var arry = Array()
			for _uid in nextNodes_index:
				arry.append([nextNodes_index[_uid], _uid])

			arry.sort_custom(func(left, right) : return left[0] < right[0] )

			#不是第一次播放
			if nextNodes_index.keys().has(_last_trans_node_uid):
				var curIndex = nextNodes_index[_last_trans_node_uid]
				for _item in arry:
					if _item[0] > curIndex:
						_last_trans_node_uid = _item[1]
						return nextNodes[_last_trans_node_uid]
				#执行到这说明这个index是最后的，重新从第一个开始播放

			_last_trans_node_uid = arry[0][1]
			return nextNodes[_last_trans_node_uid]

		Utility.RandomHelper.Method.Random:
			var filter_dict = Utility.dict_filter(nextNodes_chance,
				func(node_uid : int, _chance : float):
					return node_uid != _last_trans_node_uid
			)

			_last_trans_node_uid = _random_node_by_chance(filter_dict)
			return nextNodes[_last_trans_node_uid]

		Utility.RandomHelper.Method.RandomNoRepeat:
			var filter_dict = Utility.dict_filter(nextNodes_chance,
				func(node_uid : int, _chance : float):
					return node_uid not in _transed_nodes_uids
			)

			if filter_dict.is_empty():
				filter_dict = Utility.dict_filter(nextNodes_chance,
					func(node_uid : int, _chance : float):
						return node_uid != _last_trans_node_uid
				)
				_transed_nodes_uids.clear()

			_last_trans_node_uid = _random_node_by_chance(filter_dict)
			_transed_nodes_uids.append(_last_trans_node_uid)
			return nextNodes[_last_trans_node_uid]

	return null


#基于dict内部的概率数据随机获取一个uid
#dict是和nextNodes_chance结构相同的uid到概率或字符串的键值对
func _random_node_by_chance(raws_dict : Dictionary) -> int:
	if raws_dict.is_empty():
		printerr("error")
		print_debug("critical error")
		return -1

	#基于变量的值将raws_dict转换为uid到float的键值对
	var dict = raws_dict.duplicate()
	for _uid in dict.keys():
		if typeof(dict[_uid]) == TYPE_STRING:
			var value = SuntomeGlobal.property_variable.value(dict[_uid])
			value = max(value, 0.0)
			dict.set(_uid, value)

	#计算总概率
	var total_chance = 0
	for _uid in dict:
		total_chance += dict[_uid]

	#随机一个[0, 总概率]的数，基于该数返回值
	var rate = Utility._rng_gene.randfn() * total_chance
	for _uid in dict:
		rate -= dict[_uid]
		if rate <= 0:
			return _uid

	var list = dict.keys()
	list.shuffle()
	return list.get(0)


func get_unused_index() -> int:
	if nextNodes_index.is_empty():
		return 1

	var ilist = range(1, nextNodes_index.size() + 1)
	var used = nextNodes_index.values()
	ilist = ilist.filter( func(i : int): return i not in used )
	if ilist.is_empty():
		return used.size() + 1

	return ilist.pop_front()


#序列化和反序列化的函数
func serialize() -> Dictionary:
	var dict := Dictionary()
	dict.set("usedTexturePath", usedTexturePath)
	if null == usedSoundObject:
		dict.set("usedSoundObject", 0)
	elif usedSoundObject.is_temp:
		dict.set("usedSoundObject", usedSoundObject.serialize())
	else:
		dict.set("usedSoundObject", usedSoundObject.name)

	dict.set("nextNodes_chance", nextNodes_chance)
	dict.set("nextNodes_index", nextNodes_index)
	dict.set("play_mode", play_mode)
	dict.set("is_transit_node", is_transit_node)
	dict.set("is_suntome", is_suntome)

	#SuntomeNodeBase的数据存储
	dict.set("position", position)
	dict.set("uid", uid)
	dict.set("nextNodes", serialize_nextNodes_info())
	return dict


#反序列化第一步，如果没有出错就返回空列表，否则返回错误信息列表
#这一步只进行节点构建，不涉及节点的连接
func unserialize_first(dict : Dictionary) -> Array:
	var errorinfo := Array()
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "usedTexturePath", self)
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "nextNodes_chance", self)
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "nextNodes_index", self)
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "play_mode", self)
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "is_transit_node", self)
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "is_suntome", self)

	#SuntomeNodeBase的数据读取
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "position", self)
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "uid", self)

	#usedSoundObject的特殊处理
	var soundobj = SuntomeSerialization.ValueFromDictOrError(errorinfo, dict, "usedSoundObject")
	if typeof(soundobj) == TYPE_STRING:
		if not SuntomeSerialization.unserialize_global.sound_object_contents.has(soundobj):
			errorinfo.append("未找到名称为 " + soundobj + " 的音频对象")
		else:
			usedSoundObject = SuntomeSerialization.unserialize_global.sound_object_contents[soundobj]
	elif typeof(soundobj) == TYPE_DICTIONARY:
		usedSoundObject = SoundObjContent.new()
		errorinfo.append_array(usedSoundObject.unserialize(soundobj))
	else :
		usedSoundObject = null

	return errorinfo


#反序列化，如果没有出错就返回空列表，否则返回错误信息列表
#这一步进行节点的连接
func unserialize_second(dict : Dictionary) -> Array:
	var errorinfo := Array()
	var list : Array = SuntomeSerialization.ValueFromDictOrError(errorinfo, dict, "nextNodes")
	errorinfo.append_array(unserialize_nextNodes_info(list))
	return errorinfo
#end(序列化和反序列化的函数)
