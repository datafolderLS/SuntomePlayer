class_name SimpleButton extends Control

signal pressed(button : SimpleButton)
signal button_gui_input(button : SimpleButton, event : InputEvent)

var _not_emit : bool = true
static var empty_pic = preload("res://misc/white.jpg")

@export var text : String:
	set(value):
		%Label.text = value
		# var x : Callable = func(): %Label.text = value
		# x.call_deferred()
		# pass
	get():
		return text


static func new_button() -> SimpleButton:
	return preload("res://misc/simple_button.tscn").instantiate()


func _ready() -> void:
	#change_color(Color.BLUE)
	pass


#用于在选择图片对象上显示简单按钮的对象
func change_color(top : Color, bottom = null):
	%picture.texture = empty_pic
	%picture.set_instance_shader_parameter("color_top", top)
	if TYPE_COLOR != typeof(bottom):
		%picture.set_instance_shader_parameter("color_bottom", top)
	else:
		%picture.set_instance_shader_parameter("color_bottom", bottom)
	pass


func set_picture(pic : Texture2D):
	if null == pic:
		return
	%picture.set_instance_shader_parameter("color_top", Color.WHITE)
	%picture.set_instance_shader_parameter("color_bottom", Color.WHITE)
	%picture.texture = pic
	text = ""
	pass


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if MOUSE_BUTTON_LEFT == event.button_index:
			if _not_emit and event.pressed:
				pressed.emit(self)
				_not_emit = false
			elif false == event.pressed:
				_not_emit = true

	button_gui_input.emit(self, event)


func change_font_color(color : Color):
	%Label.add_theme_color_override("font_color", color)
	pass


func update_from_info(info : SelectPicContent.SelectButtonInfo):
	anchor_left = info.pos.x
	anchor_top = info.pos.y
	anchor_right = info.pos.x + info.size.x
	anchor_bottom = info.pos.y + info.size.y

	if info.isPicture and info.picpath.length() > 0:
		var picture = TextureCenter.get_picture(info.picpath)
		if null == picture:
			text = tr("error")
			change_color(Color.WEB_GRAY)
			change_font_color(Color.RED)
			return

		set_picture(picture)
		var pic_size = picture.get_size()
		# var scaled_size_y = info.size.x * pic_size.y / pic_size.x
		_fit_static_size(pic_size.y / pic_size.x)
		pass
	else:
		if info.name_as_text:
			text = info.name
		else:
			text = info.text

		change_color(info.bgcolor)
		change_font_color(info.fontcolor)


#基于info的信息在pNode下创建一个SimpleButton
static func create_button_from_button_info(pNode : Node, info : SelectPicContent.SelectButtonInfo) -> SimpleButton:
	var addone = SimpleButton.new_button()
	addone.hide()
	pNode.add_child(addone)

	addone.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT)
	addone.set_begin(Vector2.ZERO)
	addone.set_end(Vector2.ZERO)

	addone.update_from_info(info)
	addone.show()
	# addone.call_deferred("show")
	return addone


#基于height_to_width_rate提供的比例将button缩放到该比例
#由于SimpleButton默认是基于anchor来进行设置的，所以这个函数还要考虑父级控件的比例
func _fit_static_size(height_to_width_rate : float):
	var _parent_size := get_parent_control().size
	var _self_width = anchor_right - anchor_left
	var _parent_wh_rate = _parent_size.x / _parent_size.y
	var target_height = _self_width * height_to_width_rate * _parent_wh_rate
	anchor_bottom = anchor_top + target_height
	pass
