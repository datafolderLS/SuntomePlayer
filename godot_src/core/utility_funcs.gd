extends Node

static var _rng_gene = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_rng_gene.randomize()
	pass # Replace with function body.


#基于enumType构造一个OptionButton用于选择enumType类型值
func make_enum_option_button(enumType) -> OptionButton:
	if TYPE_DICTIONARY != typeof(enumType):
		return null

	var ctrl = OptionButton.new()
	for key in enumType.keys():
		ctrl.add_item(key, enumType[key])
	# for n in enumType.keys():
	return ctrl


#工具函数，将parent的所有子节点全部删除，可选参数函数对象checkFunc(Node)用于对子节点进行筛选
func remove_all_child(parent : Node, checkFunc : Callable = Callable()):
	var all = parent.get_children()
	if null != checkFunc and checkFunc.is_valid():
		for n in all:
			if checkFunc.call(n):
				parent.remove_child(n)
				n.queue_free()
	else:
		for n in all:
			parent.remove_child(n)
			n.queue_free()
	pass


#工具函数，将parent的所有子节点全部移除并返回，可选参数函数对象checkFunc(Node)用于对子节点进行筛选
func remove_all_child_and_return(parent : Node, checkFunc : Callable = Callable()) -> Array:
	var rel = Array()
	var all = parent.get_children()
	if null != checkFunc and checkFunc.is_valid():
		for n in all:
			if checkFunc.call(n):
				parent.remove_child(n)
				rel.append(n)
	else:
		for n in all:
			parent.remove_child(n)
			rel.append(n)

	return rel


#将绝对路径filePath改为以./data打头的路径
func cut_file_path(filePath : String) -> String:
	if filePath.is_absolute_path():
		var root = SuntomeGlobal.root_path()
		if filePath.begins_with(root):
			filePath = filePath.erase(0, root.length())
			filePath = "." + filePath

	return filePath


#将相对路径转为绝对路径
func relative_to_full(filePath : String) -> String:
	if filePath.is_absolute_path():
		return filePath

	var root = SuntomeGlobal.root_path()
	# var root = OS.get_executable_path().get_base_dir()
	# if OS.has_feature("editor") :
	# 	root = "res://"
	if filePath.left(2) == "./" or filePath.left(2) == ".\\":
		filePath = filePath.erase(0, 2)
	var abpath = root.path_join(filePath)
	return abpath



#随机抽取辅助对象，用于随机抽取Array和Dictionary中的对象
class RandomHelper extends RefCounted:
	enum Method {
		Sequence,        #顺序
		Random,          #随机抽取
		RandomNoRepeat,  #不放回随机抽取
	}

	var method_type : Method = Method.Sequence

	var cur_index : Callable
	var index_to_key : Callable

	#辅助随机遍历的变量，由_get_next_randomly_norepeat自己初始化
	var _IndexList : Array

	#辅助顺序播放和随机播放的变量
	var currentIndex : int = -1
	var currentValue

	static var rng = RandomNumberGenerator.new()

	func change_method_type(me : Method):
		method_type = me
		pass


	func next(list):
		match method_type:
			Method.Sequence:
				return _get_next_sequentialy(list)
			Method.RandomNoRepeat:
				return _get_next_randomly_norepeat(list)
			Method.Random:
				return _get_next_randomly(list)
		pass


	func _get_next_sequentialy(list):
		currentIndex = (currentIndex + 1) % list.size()
		return index_to_key.call(currentIndex)


	func _get_next_randomly(list):
		var add = rng.randi_range(1, list.size() - 1)
		currentIndex = (currentIndex + add) % list.size()
		return index_to_key.call(currentIndex)
	pass

	func _get_next_randomly_norepeat(list):
		if _IndexList.is_empty():
			_IndexList = range(list.size())
			_IndexList.shuffle()

		if _IndexList.size() < 2:
			currentIndex = _IndexList.pop_front()
			return index_to_key.call(currentIndex)

		var nextIndex = _IndexList.pop_front()

		#避免重复
		if nextIndex == currentIndex:
			nextIndex = _IndexList.pop_front()
			_IndexList.push_back(currentIndex)

		currentIndex = nextIndex
		return index_to_key.call(currentIndex)

	func _construct_from_value(list) -> bool:
		if list is Array:
			index_to_key = func(i : int): return i
			pass
		elif list is Dictionary:
			var keys = list.keys()
			index_to_key = func(i : int):
				return keys.get(i)
			pass
		else:
			return false

		return true


func ConstructRandomHelper(list) -> RandomHelper:
	var rel = RandomHelper.new()

	if not rel._construct_from_value(list):
		print("list is unsupported type : ", typeof(list))
		return null

	return rel


class RandomHelperArray extends RefCounted:

	func _get_next_sequentialy(list : Array, pre_index : int):
		var next = (pre_index + 1) % list.size()
		return list.get(next)
	pass

	func _get_next_randomly(list : Array, pre_index : int):
		var add = Utility._rng_gene.randi_range(1, list.size() - 1)
		var next = (pre_index + add) % list.size()
		return list.get(next)
	pass

	func _get_next_randomly_norepeat(list : Array, used_index_list : Array):
		var remain_index = range(list.size()).filter(func(value) : return value not in used_index_list)
		if remain_index.is_empty():
			remain_index = range(list.size())

		remain_index.shuffle()

		var nextIndex = remain_index.pop_front()

		return list.get(nextIndex)


class RandomHelperDictionary extends RefCounted:

	func _get_next_sequentialy(list : Array, pre_index : int):
		var next = (pre_index + 1) % list.size()
		return list.get(next)
	pass

	func _get_next_randomly(list : Array, pre_index : int):
		var add = Utility._rng_gene.randi_range(1, list.size() - 1)
		var next = (pre_index + add) % list.size()
		return list.get(next)
	pass

	func _get_next_randomly_norepeat(list : Array, used_index_list : Array):
		var remain_index = range(list.size()).filter(func(value) : return value not in used_index_list)
		if remain_index.is_empty():
			remain_index = range(list.size())

		remain_index.shuffle()

		var nextIndex = remain_index.pop_front()

		return list.get(nextIndex)


func dict_filter(dict : Dictionary, check : Callable) -> Dictionary:
	var newDict = Dictionary()
	for _key in dict:
		if check.call(_key, dict[_key]):
			newDict.set(_key, dict[_key])
	return newDict


#传入一个字符串和字符串列表，如果字符串在列表中有重复的对象，
#就在check_name字符串后面加上.{num}后缀，其中num是没有重复的后缀对象
func check_no_repeat_name(check_name : String, nameList : Array) -> String:
	if check_name in nameList:
		var append = 1
		while true:
			var x = check_name + "." + String.num_int64(append)
			if nameList.find(x) < 0:
				check_name = x
				break
			append += 1

	return check_name


func node_all_children(parent : Node) -> Array:
	var result = Array()

	var list = parent.get_children(false)
	result.append_array(list)

	while list.size() > 0:
		var p = list.pop_front()
		var cs = p.get_children(false)
		result.append_array(cs)
		list.append_array(cs)

	return result


#返回路径文件的后缀名，小写，如果没有后缀名返回空字符串
func file_suffix(path : String) -> String:
	var suffixCheck = path.rsplit(".", true, 1)
	if suffixCheck.size() < 1:
		return ""
	var type = suffixCheck[1].to_lower()
	return type
