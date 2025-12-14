extends Control

func _ready() -> void:
	var ctt = SelectPicContent.new()
	ctt.usedTexturePath = Utility.cut_file_path("./data/新建文件夹/cover.jpg")
	%select_pic_editor.set_current_pic_content(ctt)
	pass
