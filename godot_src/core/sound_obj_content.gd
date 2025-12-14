extends RefCounted

class_name SoundObjContent
#SoundObjContent是用于存储的SoundObjEdit的编辑对象，里面存储了所有的音频节点和输出节点的位置信息
#可以基于SoundObjContent构造一个SoundObject对象

class NodeInfo extends RefCounted:
	var offset_pos : Vector2  #在sound_obj_edit中的偏移坐标
	var path : String         #音频文件相对路径
	var has_connected : bool  #是否和输出节点连接

var name : String                       #该对象的名称
#一个NodeInfo对象列表
var sound_nodes : Array
var out_offset_pos : Vector2 = Vector2(200,200)   #输出节点的坐标，默认为(200,200)
var play_method : Utility.RandomHelper.Method = Utility.RandomHelper.Method.RandomNoRepeat   #音频节点的随机方式
var is_temp : bool = false    #标记是否是临时音频对象

var name_change_cb : Callable           #当用户修改了name时，触发该函数对象
var before_delete_cb : Callable         #当用户删除该对象时，触发该函数对象

var _now_play_sound : NodeInfo          #记录当前正在播放使用的NodeInfo

var _used_nodeinfos : Array = Array()   #记录已经播放过的NodeInfo

signal name_changed_sig(node : SoundObjContent)
signal before_delete_sig(node : SoundObjContent)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

#基于sound_nodes的位置进行排序
func _sort_sound_nodes_by_pos(sound_nodes_in : Array):
	sound_nodes_in.sort_custom(func(left : NodeInfo, right : NodeInfo):
		return left.offset_pos.y < right.offset_pos.y
	)
	return sound_nodes_in


#构造一个临时的音频对象（音频对象不在SuntomeGlobal.sound_object_contents中，且is_temp为true
static func make_temp_soundobj(path : String) -> SoundObjContent:
	var tempSoundObj = SoundObjContent.new()
	tempSoundObj.is_temp = true
	tempSoundObj.change_name(Utility.cut_file_path(path))
	var newNodeInfo = SoundObjContent.NodeInfo.new()
	newNodeInfo.offset_pos = Vector2.ZERO
	newNodeInfo.path = path
	newNodeInfo.has_connected = true
	tempSoundObj.sound_nodes.append(newNodeInfo)
	return tempSoundObj


#返回node下面的第一个节点，如果node已是最后一个节点，返回null
func _get_near_next_node(node : NodeInfo) -> NodeInfo:
	# var yp = node.offset_pos.y
	var pass_nodes = sound_nodes.filter(
		func(n : NodeInfo):
			if node == n:
				return false

			return n.offset_pos.y > node.offset_pos.y
	)

	if pass_nodes.is_empty():
		return null

	pass_nodes = _sort_sound_nodes_by_pos(pass_nodes)
	return pass_nodes.get(0)


func get_next_sound() -> String:
	if sound_nodes.is_empty():
		print_debug("error no sound bind yet")
		return ""

	if sound_nodes.size() == 1:
		_now_play_sound = sound_nodes.get(0)
		return _now_play_sound.path

	match play_method:
		Utility.RandomHelper.Method.Sequence:
			sound_nodes = _sort_sound_nodes_by_pos(sound_nodes)
			if null == _now_play_sound:
				_now_play_sound = sound_nodes.get(0)
				return _now_play_sound.path

			var next = _get_near_next_node(_now_play_sound)
			if null == next:
				_now_play_sound = sound_nodes.get(0)
				return _now_play_sound.path

			_now_play_sound = next
			return _now_play_sound.path

		Utility.RandomHelper.Method.Random:
			var filter = sound_nodes.filter(func(node : NodeInfo): return node != _now_play_sound)
			_now_play_sound = filter.get(Utility._rng_gene.randi() % filter.size())
			return _now_play_sound.path

		Utility.RandomHelper.Method.RandomNoRepeat:
			var filter = sound_nodes.filter(func(node : NodeInfo): return node not in _used_nodeinfos)
			if filter.is_empty():
				filter = sound_nodes.filter(func(node : NodeInfo): return node != _now_play_sound)
				_used_nodeinfos.clear()

			_now_play_sound = filter.get(Utility._rng_gene.randi() % filter.size())
			_used_nodeinfos.append(_now_play_sound)
			return _now_play_sound.path

	# if null == _now_play_sound:
	# 	_sound_obj = make_soundobject()

	return "error path"


func change_name(new_name : String):
	name = new_name
	if name_change_cb.is_valid():
		name_change_cb.call(self)

	name_changed_sig.emit(self)


func before_delete():
	if before_delete_cb.is_valid():
		before_delete_cb.call(self)

	before_delete_sig.emit(self)

func get_sound_node_by_path(path : String):
	for node in sound_nodes:
		if node.path == path:
			return node

	return null


#序列化和反序列化的函数
func serialize() -> Dictionary:
	var dict := Dictionary()
	dict.set("name", name)
	dict.set("out_offset_pos", out_offset_pos)
	dict.set("play_method", play_method)
	dict.set("is_temp", is_temp)
	var snode := Array()
	for info : NodeInfo in sound_nodes:
		var sdic := Dictionary()
		sdic.set("offset_pos", info.offset_pos)
		sdic.set("path", info.path)
		sdic.set("has_connected", info.has_connected)
		snode.append(sdic)

	dict.set("sound_nodes", snode)
	return dict


#反序列化，如果没有出错就返回空列表，否则返回错误信息列表
func unserialize(dict : Dictionary) -> Array:
	var errorinfo := Array()
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "name", self)
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "out_offset_pos", self)
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "play_method", self)
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "is_temp", self)
	sound_nodes.clear()
	var snode = SuntomeSerialization.ValueFromDictOrError(errorinfo, dict, "sound_nodes")
	if null != snode:
		for sdic : Dictionary in snode:
			var info = NodeInfo.new()
			SuntomeSerialization.SetValueFromDictOrError(errorinfo, sdic, "offset_pos", info)
			SuntomeSerialization.SetValueFromDictOrError(errorinfo, sdic, "path", info)
			SuntomeSerialization.SetValueFromDictOrError(errorinfo, sdic, "has_connected", info)
			sound_nodes.append(info)

	return errorinfo
#end(序列化和反序列化的函数)
