class_name ParaNodeSettingCtrl extends HBoxContainer

signal text_change(pretext : String, text : String)
signal req_delete(ctrl : ParaNodeSettingCtrl)
signal value_change(ctrl : ParaNodeSettingCtrl, value : float)

var _pretext : String

#获取其他文字选项的函数，用于对用户输入的字符串进行合法性检查()->Array(String)
var get_all_other_text : Callable = Callable()

static func create(text : String) -> ParaNodeSettingCtrl:
	var ctrl = preload("res://editor/base/para_node_setting_ctrl.tscn").instantiate()
	ctrl.get_node("%LineEdit").text = text
	ctrl._pretext = text
	return ctrl


func _ready() -> void:
	%LineEdit.editing_toggled.connect(func(v : bool) :
		if v:
			return
		if _text_valid_check(%LineEdit.text):
			_text_commit(%LineEdit.text)
	)
	%LineEdit.text_changed.connect(func(text : String):
		if _text_valid_check(text):
			%LineEdit.remove_theme_color_override("font_color")
		else:
			%LineEdit.add_theme_color_override("font_color", Color.RED)
		pass
	)

	%button_remove.pressed.connect(func() : req_delete.emit(self))

	%SpinBox.value_changed.connect(func(v : float): value_change.emit(self, v))
	pass


func _text_valid_check(text : String) -> bool:
	if text.remove_chars(" \t").is_empty():
		return false

	if not get_all_other_text.is_valid():
		return true

	var alltext = get_all_other_text.call()
	alltext.erase(_pretext)
	if text in alltext:
		return false
	return true


func _text_commit(text : String):
	var temp = _pretext
	_pretext = text
	text_change.emit(temp, text)
	# print(text)


func current_text() -> String:
	return _pretext


func value() -> float:
	return %SpinBox.value
