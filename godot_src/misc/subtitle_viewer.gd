extends Control
#用于显示字幕的控件

#控件用于获取当前应该显示的台词
var get_now_subtitle : Callable = Callable()
var pre_sub_title : String = String()

func _ready() -> void:
	%AutoSizeLabel.text = ""


func _process(_delta: float) -> void:
	if get_now_subtitle.is_valid():
		var now_sub = get_now_subtitle.call()
		if now_sub != pre_sub_title:
			pre_sub_title = now_sub
			%AutoSizeLabel.text = now_sub
	else:
		if "" != pre_sub_title:
			pre_sub_title = ""
			%AutoSizeLabel.text = pre_sub_title


func set_max_size(font_size : int):
	font_size = max(16, font_size)
	%AutoSizeLabel._max_size = font_size
