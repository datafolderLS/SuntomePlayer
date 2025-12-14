class_name SliderOfVector2 extends VBoxContainer

@export var param_name : String

var value : Vector2 :
	get():
		return _inner_value

	set(v):
		_inner_value = v
		%vec1_slider.set_value_no_signal(v.x)
		%vec2_slider.set_value_no_signal(v.y)
		%part1.set_value_no_signal(v.x)
		%part2.set_value_no_signal(v.y)
		value_changed.emit(_inner_value)

var _inner_value : Vector2

signal value_changed(value : Vector2)

#当对象的值被非refresh函数更改时，调用该函数对象，传入参数为(param_name : String, value : Variant)
#该函数对象由ParamEditRoot设置
var value_updated : Callable


func set_value_no_signal(v : Vector2):
	_inner_value = v
	%vec1_slider.set_value_no_signal(v.x)
	%vec2_slider.set_value_no_signal(v.y)
	%part1.set_value_no_signal(v.x)
	%part2.set_value_no_signal(v.y)
	pass


func _ready() -> void:
	%part1.value_changed.connect(func(v : float):
		_inner_value.x = v
		%vec1_slider.set_value_no_signal(v)
		value_changed.emit(_inner_value)
	)

	%part2.value_changed.connect(func(v : float):
		_inner_value.y = v
		%vec2_slider.set_value_no_signal(v)
		value_changed.emit(_inner_value)
	)

	%vec1_slider.value_changed.connect(func(v : float):
		_inner_value.x = v
		%part1.set_value_no_signal(v)
		value_changed.emit(_inner_value)
	)

	%vec2_slider.value_changed.connect(func(v : float):
		_inner_value.y = v
		%part2.set_value_no_signal(v)
		value_changed.emit(_inner_value)
	)

	value_changed.connect(
		func(v : Vector2):
			if value_updated.is_valid() and not param_name.is_empty():
				value_updated.call(param_name, v)
	)


func set_x_range(range_ : Vector2):
	var min_ = min(range_.x, range_.y)
	var max_ = max(range_.x, range_.y)
	%part1.min_value = min_
	%part1.max_value = max_
	%vec1_slider.min_value = min_
	%vec1_slider.max_value = max_


func set_y_range(range_ : Vector2):
	var min_ = min(range_.x, range_.y)
	var max_ = max(range_.x, range_.y)
	%part2.min_value = min_
	%part2.max_value = max
	%vec2_slider.min_value = min_
	%vec2_slider.max_value = max_


#为ParamEditRoot准备的函数
func refresh(obj):
	if param_name.is_empty():
		return

	var value_ = obj.get(param_name)
	if typeof(value_) == TYPE_VECTOR2:
		set_value_no_signal(value_)


func update_value(obj):
	if param_name.is_empty():
		return

	var val = obj.get(param_name)
	if typeof(val) == TYPE_VECTOR2:
		obj.set(param_name, value)
