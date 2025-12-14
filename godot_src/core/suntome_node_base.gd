class_name SuntomeNodeBase extends RefCounted

#相连的节点信息，键值对类型为{uid : int, SuntomeNode}
var nextNodes : Dictionary = {}

#该节点在editor中的坐标
var position : Vector2

#唯一标识符，用于标记SuntomeNode，范围为0~4294967295
var uid : int

#生成一个随机的和当前已有的uid不同的uid
static func random_uid() -> int:
	var exist_uids = SuntomeGlobal.suntome_nodes.keys()
	return Utility.make_uniq_uid(exist_uids)


#用于序列化和反序列化的函数
func serialize_nextNodes_info() -> Array:
	var list := Array()
	for _uid in nextNodes:
		list.append(_uid)
	return list


#反序列化，如果没有出错就返回空列表，否则返回错误信息列表
func unserialize_nextNodes_info(list : Array, mapcbs : SuntomeSerialization.GlobalInfoMapCBs) -> Array:
	var errorinfo := Array()
	for _uids in list:
		var _uid = mapcbs.uid_map_cb.call(_uids)
		if null == _uid:
			errorinfo.append("反序列化失败, uid：" + String.num_int64(_uids) + " 映射不存在")
			continue

		var node = mapcbs.suntomenode_map_cb.call(_uid)
		if null == node:
			errorinfo.append("反序列化失败, uid：" + String.num_int64(_uid) + " 不存在")
			continue

		# if not SuntomeSerialization.unserialize_global.suntome_nodes.has(_uid):
		# 	errorinfo.append("反序列化失败, uid：" + String.num_int64(_uid) + " 不存在")
		# 	continue
		var rightNode : SuntomeNodeBase = node
		nextNodes.set(_uid, rightNode)

	return errorinfo
#end(用于序列化和反序列化的函数)
