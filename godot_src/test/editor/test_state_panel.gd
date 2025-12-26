extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var panel : StatePanel = get_node("StatePanel")
	var node1 = panel.new_node()
	node1.position = Vector2(200,200)
	var node2 = panel.new_node()
	# panel.connect_node(node1, node2)
	#panel.connect_node(node2, node1)
	panel.node_delete_check_func =  func(node : StateNode) -> bool :
			print("node delete check")
			return true
	panel.line_delete_check_func = func(line : StateLine) -> bool :
		print("line delete check")
		return true

	panel.line_connect_check_func = func(left : StateNode, right : StateNode) -> bool :
		print("line connect check")

		call_deferred("_test")
		return true

	get_node("Button").pressed.connect(_add_node_random)

	var ctrl := Label.new()
	ctrl.text = "测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试"
	#ctrl.custom_minimum_size = ctrl.size
	node1.container.add_child(ctrl)

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _add_node_random():
	var panel : StatePanel = get_node("StatePanel")
	var node1 = panel.new_node()
	node1.position = Vector2(randf_range(0, 500),randf_range(0, 500))


func _test():
	var panel : StatePanel = get_node("StatePanel")
	panel.each_node(func(nd : StateNode):
		var lines = panel.lines_from_node(nd)
		for line in lines:
			line.set_label("long enough")
	)
