class_name Queue extends RefCounted

var _data : Array = Array()
var max_size : int= 0


static func make_queue(size : int) -> Queue:
	var q = Queue.new()
	q.max_size = size
	return q


func add(obj) -> Queue:
	_data.append(obj)
	if _data.size() > max_size:
		_data.remove_at(0)
	return self


func head():
	return _data.front()


func end():
	return _data.back()


func pop_front():
	return _data.pop_front()


func foreach(cb : Callable) -> Queue:
	if cb.is_valid():
		for obj in _data:
			cb.call(obj)
	return self
