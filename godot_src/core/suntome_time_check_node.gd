#设置时间检查节点，用于检查标签时间是否已满足
class_name SuntomeTimeCheckNode extends "res://core/suntome_node_base.gd"

#该节点表示检查的时间标签
var checked_time_tag := String()
#允许通过的节点的uid，小于0表示无效
var success_node_uid : int = -1
#检查时间，单位为秒
var checked_time : float = 0.0


static func new_node() -> SuntomeTimeCheckNode:
	var newNode := SuntomeTimeCheckNode.new()
	newNode.uid = SuntomeNodeBase.random_uid()
	return newNode


#返回该类型的判别名
static func normal_key()->String:
	return "TYPE_SuntomeTimeCheckNode"


# func do_operation():
# 	for key in change_operation:
# 		SuntomeGlobal.property_variable.setv(key, change_operation[key])


func next_node() -> SuntomeNodeBase:
	if nextNodes.is_empty():
		return null

	var start_time = SuntomeGlobal.time_check_map.get(checked_time_tag)
	if null == start_time:
		printerr("time tag: {0} not exist".format([checked_time_tag]))
		start_time = 3600000000

	var allnode = nextNodes.values()
	var passed_node : SuntomeNodeBase = nextNodes.get(success_node_uid)
	allnode.erase(passed_node)
	var failnode = allnode.get(0)

	var now_time = SuntomeGlobal.now_time() - start_time
	if now_time > checked_time:
		return passed_node
	else:
		return failnode


#序列化和反序列化的函数
func serialize() -> Dictionary:
	var dict := Dictionary()
	dict.set("checked_time_tag", checked_time_tag)
	dict.set("checked_time", checked_time)
	dict.set("success_node_uid", success_node_uid)

	#SuntomeNodeBase的数据存储
	dict.set("position", position)
	dict.set("uid", uid)
	dict.set("nextNodes", serialize_nextNodes_info())
	return dict


#反序列化第一步，如果没有出错就返回空列表，否则返回错误信息列表
#这一步只进行节点构建，不涉及节点的连接
func unserialize_first(dict : Dictionary, _mapcbs : SuntomeSerialization.GlobalInfoMapCBs) -> Array:
	var errorinfo := Array()
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "checked_time_tag", self)
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "checked_time", self)

	#SuntomeNodeBase的数据读取
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "position", self)
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "uid", self)
	return errorinfo


#反序列化，如果没有出错就返回空列表，否则返回错误信息列表
#这一步进行节点的连接
func unserialize_second(dict : Dictionary, mapcbs : SuntomeSerialization.GlobalInfoMapCBs) -> Array:
	var errorinfo := Array()
	var list : Array = SuntomeSerialization.ValueFromDictOrError(errorinfo, dict, "nextNodes")
	errorinfo.append_array(unserialize_nextNodes_info(list, mapcbs))

	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "success_node_uid", self)
	var uidmaped = mapcbs.uid_map_cb.call(success_node_uid)
	if null == uidmaped:
		success_node_uid = -1
	else :
		success_node_uid = uidmaped

	return errorinfo
#end(序列化和反序列化的函数)
