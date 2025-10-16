#设置修改节点，包含创建和修改变量的值
class_name SuntomeParaNode extends "res://core/suntome_node_base.gd"

#该节点执行的修改变量值操作，数据类型为{name : String, value : float}
var change_operation := Dictionary()

static func new_node() -> SuntomeParaNode:
	var newNode := SuntomeParaNode.new()
	newNode.uid = SuntomeNodeBase.random_uid()
	return newNode


func do_operation():
	for key in change_operation:
		SuntomeGlobal.property_variable.setv(key, change_operation[key])


func next_node() -> SuntomeNodeBase:
	if nextNodes.is_empty():
		return null
	return nextNodes.values().get(0)


#序列化和反序列化的函数
func serialize() -> Dictionary:
	var dict := Dictionary()
	dict.set("change_operation", change_operation)

	#SuntomeNodeBase的数据存储
	dict.set("position", position)
	dict.set("uid", uid)
	dict.set("nextNodes", serialize_nextNodes_info())
	return dict


#反序列化第一步，如果没有出错就返回空列表，否则返回错误信息列表
#这一步只进行节点构建，不涉及节点的连接
func unserialize_first(dict : Dictionary) -> Array:
	var errorinfo := Array()
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "change_operation", self)

	#SuntomeNodeBase的数据读取
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "position", self)
	SuntomeSerialization.SetValueFromDictOrError(errorinfo, dict, "uid", self)
	return errorinfo


#反序列化，如果没有出错就返回空列表，否则返回错误信息列表
#这一步进行节点的连接
func unserialize_second(dict : Dictionary) -> Array:
	var errorinfo := Array()
	var list : Array = SuntomeSerialization.ValueFromDictOrError(errorinfo, dict, "nextNodes")
	errorinfo.append_array(unserialize_nextNodes_info(list))
	return errorinfo
#end(序列化和反序列化的函数)