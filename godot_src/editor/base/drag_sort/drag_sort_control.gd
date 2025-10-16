class_name DragSortControl extends MarginContainer

#用于实现类似Editor的对array数据结构进行排序操作的控件

signal order_changed()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _make_content_pool(content : Control) -> Control:
	var newpool = preload("res://editor/base/drag_sort/drag_able_item.tscn").instantiate()
	var container = newpool.container()
	container.add_child(content)
	newpool.index_changed.connect(
		func(_item : DragAbleItem):
			order_changed.emit()
	)
	return newpool

#填充内容，nodes的成员必须是Control子类型
#这些nodes会直接显示在界面上
#注意在调用前要先调用remove_all_content_and_return获取成员，否则会造成内存泄露
func set_array(nodes : Array):
	var all = remove_all_content_and_return()
	for i in all:
		i.queue_free()

	for n in nodes:
		if n is Control:
			%boxcontainer.add_child(_make_content_pool(n))
			#%boxcontainer.add_child(_separator())
		else:
			print_debug("error n is not a Control")
			return
	pass


#清空所有成员对象（注意这里不会删除对象
func remove_all_content_and_return() -> Array:
	var rel = Array()
	var all = Utility.remove_all_child_and_return(%boxcontainer)
	for i in all:
		var node = i.remove_content_and_return()
		rel.append(node)
		i.queue_free()

	return rel


#获取内容，返回排过序的set_array入参
func get_array() -> Array:
	var rel = Array()
	var max_i = %boxcontainer.get_child_count()
	for i in range(max_i):
		var node = %boxcontainer.get_child(i).content()
		rel.append(node)

	return rel
