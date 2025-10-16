#变量仓库，用于用户自定义变量的值
class_name  VariableProp extends RefCounted


var _dicdata := Dictionary()

#获取哦key键指向的值，如果键不存在，返回负数
func value(key : String) -> float:
	if _dicdata.has(key):
		return _dicdata[key]

	return -1.0

func setv(key : String, _v : float):
	if _v < 0.0:
		_v = 0.0
	_dicdata.set(key, _v)


func all_keys() -> Array:
	return _dicdata.keys()