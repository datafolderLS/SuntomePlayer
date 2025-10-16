class_name ParamEditControl extends Control

#修改的成员变量名称
@export var param_name : String

#脚本支持控件的属性映射表
static var ParamMapDict : Dictionary = {
	"LineEdit"           : [TYPE_STRING, "text", "text_changed", true],
	"CheckBox"           : [TYPE_BOOL, "button_pressed", "pressed", false],
	"SpinBox"            : [TYPE_FLOAT, "value", "value_changed", true],
	"Slider"             : [TYPE_FLOAT, "value", "value_changed", true],
	"ColorPickerButton"  : [TYPE_COLOR, "color", "color_changed", true],
}

#当对象的值被非refresh函数更改时，调用该函数对象，传入参数为(param_name : String, value : Variant)
#该函数对象由ParamEditRoot设置
var value_updated : Callable


func _ready() -> void:
	for key in ParamMapDict:
		if is_class(key):
			var rr = ParamMapDict[key]
			if rr.size() <= 3:
				break

			if rr[3]:
				connect(rr[2], func(_value):
					if value_updated.is_valid() and (not param_name.is_empty()):
						var v = self.get(rr[1])
						value_updated.call(param_name, v)
				)
			else:
				connect(rr[2], func():
					if value_updated.is_valid() and (not param_name.is_empty()):
						var v = self.get(rr[1])
						value_updated.call(param_name, v)
				)
	pass


#基于obj和param_name来更新控件的值
func refresh(obj):
	if param_name.is_empty():
		return
	var val = obj.get(param_name)
	if null == val:
		return

	#if is_class("LineEdit"):
		#if typeof(val) == TYPE_STRING:
			#self.text = val
	#elif is_class("CheckBox"):
		#if typeof(val) == TYPE_BOOL:
			#self.button_pressed = val

	for key in ParamMapDict:
		if is_class(key):
			var rr = ParamMapDict[key]
			if typeof(val) == rr[0]:
				set_block_signals(true)
				self.set(rr[1], val)
				set_block_signals(false)
			else:
				printerr("value type not currect")
			return

	#如果函数跑到这，说明是不支持的控件
	printerr("unsurported class type:  ", get_class())
	pass


#基于param_name和控件的值来更新obj中对应的值
func update_value(obj):
	if param_name.is_empty():
		return

	var val = obj.get(param_name)
	if null == val:
		return

	for key in ParamMapDict:
		if is_class(key):
			var rr = ParamMapDict[key]
			if typeof(val) == rr[0]:
				var v = self.get(rr[1])
				obj.set(param_name, v)
			else:
				printerr("value type not currect")
			break
	pass
