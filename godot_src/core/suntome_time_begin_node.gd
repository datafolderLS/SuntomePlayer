#设置修改节点，包含创建和修改变量的值
class_name SuntomeTimeBeginNode extends "res://core/suntome_node_base.gd"

#该节点执行的记录时间的标签，默认为suntome time
var time_tag := "suntome time"

static func new_node() -> SuntomeTimeBeginNode:
	var newNode := SuntomeTimeBeginNode.new()
	newNode.uid = SuntomeNodeBase.random_uid()
	return newNode


#返回该类型的判别名
static func normal_key()->String:
	return "TYPE_SuntomeTimeBeginNode"


func do_operation():
	SuntomeGlobal.time_check_map.set(time_tag, SuntomeGlobal.now_time())


func next_node() -> SuntomeNodeBase:
	if nextNodes.is_empty():
		return null
	return nextNodes.values().get(0)


#序列化和反序列化的函数
func serialize() -> Dictionary:
	var dict := Dictionary()
	dict.set("time_tag", time_tag)

	#SuntomeNodeBase的数据存储
	dict.set("position", position)
	dict.set("uid", uid)
	dict.set("nextNodes", serialize_nextNodes_info())
	return dict


#反序列化第一步，如果没有出错就返回空列表，否则返回错误信息列表
#这一步只进行节点构建，不涉及节点的连接
func unserialize_first(dict : Dictionary, _mapcbs : SuntomeSerialization.GlobalInfoMapCBs) -> Array:
	var errorinfo := Array()
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "time_tag", self)

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
	return errorinfo
#end(序列化和反序列化的函数)
