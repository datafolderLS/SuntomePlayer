#设置寸止次数添加节点
class_name SuntomeCountCheckNode extends "res://core/suntome_node_base.gd"

#允许检查通过的寸止次数
var pass_count : int = 0
#允许通过的节点的uid，小于0表示无效
var success_node_uid : int = -1


#返回该类型的判别名
static func normal_key()->String:
	return "TYPE_SuntomeCountCheckNode"


static func new_node() -> SuntomeCountCheckNode:
	var newNode := SuntomeCountCheckNode.new()
	newNode.uid = SuntomeNodeBase.random_uid()
	return newNode


func next_node() -> SuntomeNodeBase:
	if nextNodes.is_empty():
		return null
	
	var allnode = nextNodes.values()

	if allnode.size() < 2:
		return allnode.get(0)
	
	var passed_node : SuntomeNodeBase = nextNodes.get(success_node_uid)
	allnode.erase(passed_node)
	var failnode = allnode.get(0)

	if SuntomeGlobal.suntome_count < pass_count:
		return failnode
	return passed_node


#序列化和反序列化的函数
func serialize() -> Dictionary:
	var dict := Dictionary()
	dict.set("pass_count", pass_count)
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
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "pass_count", self)

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
