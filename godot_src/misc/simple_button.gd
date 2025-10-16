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
	%picture.material.set_shader_parameter("color_top", top)
	if TYPE_COLOR != typeof(bottom):
		%picture.material.set_shader_parameter("color_bottom", top)
	else:
		%picture.material.set_shader_parameter("color_bottom", bottom)
	pass


func set_picture(pic : Texture2D):
	if null == pic:
		return
	%picture.material.set_shader_parameter("color_top", Color.WHITE)
	%picture.material.set_shader_parameter("color_bottom", Color.WHITE)
	%picture.texture = pic
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
	if info.name_as_text:
		text = info.name
	else:
		text = info.text

	change_color(info.bgcolor)
	change_font_color(info.fontcolor)


#基于info的信息在pNode下创建一个SimpleButton
static func create_button_from_button_info(pNode : Node, info : SelectPicContent.SelectButtonInfo) -> SimpleButton:
	var addone = SimpleButton.new_button()
	pNode.add_child(addone)

	addone.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT)
	addone.set_begin(Vector2.ZERO)
	addone.set_end(Vector2.ZERO)

	addone.update_from_info(info)
	return addone
