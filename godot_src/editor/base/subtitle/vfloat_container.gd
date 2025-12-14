class_name VFloatContainer extends PanelContainer

#让子控件一直顶在上方的容器，偏移的参考以refrence_control为准，
#如果refrence_control为空，容器的表现和margin为0的margincontainer一致

@export var refrence_control : Control

func _ready() -> void:
	set_notify_transform(true)
	item_rect_changed.connect(_sort_children)
	mouse_filter = Control.MOUSE_FILTER_PASS


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			_sort_children()
		NOTIFICATION_THEME_CHANGED:
			update_minimum_size()
		NOTIFICATION_TRANSFORM_CHANGED:
			_sort_children()
	pass


func _sort_children():
	if refrence_control:
		var x = refrence_control.global_position
		var diff = (global_position - x).y
		var access_diff = diff
		for c : Control in get_children():
			access_diff = clamp(-diff, 0, size.y - c.size.y)
			fit_child_in_rect(c, Rect2(0, access_diff, size.x, c.size.y))
		pass
	else:
		for c : Control in get_children():
			fit_child_in_rect(c, Rect2(Vector2.ZERO, size))



func _get_minimum_size() -> Vector2:
	var maxs := Vector2.ZERO

	for c : Control in get_children():
		var cmax = c.get_combined_minimum_size()
		maxs = maxs.max(cmax)

	return maxs
