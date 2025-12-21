extends Node

#全局单例对象，存储了游戏全局的音频对象列表、音频节点列表、节点连线列表
class_name suntome_global

#数据结构的版本信息
const Data_Version = 0.1

#当前工程中所有的SoundObjContent对象，内容为{obj_name, SoundObjContent}
var sound_object_contents := {}

#当前工程中所有的SelectPicContent对象，内容为{obj_name, SelectPicContent}
var select_pic_contents := {}

#当前工程中所有的SuntomeNodeBase对象，数据为{uid : int, SuntomeNodeBase}
var suntome_nodes := Dictionary()

#开始节点
@onready var begin_node := SuntomeNode.new_transit_node()

#当用户点击漏了时的触发节点
@onready var sourou_node := SuntomeNode.new_transit_node()

#音频文件和字幕文件绑定信息，键值对为{音频文件路径, 字幕文件路径}
var sound_subtitle_bind_info := Dictionary()

#用户寸止次数计数
var suntome_count : int = 0

#辅助变量，用于记录当前流程中的所有变量信息
var property_variable := VariableProp.new()

#时间tag，用于记录各标签时间的开始时间{name : String, time : float}
var time_check_map := Dictionary()

const SaveFile = "play_file.suntome"

#节点处理错误信号，当节点播放出现错误时，该信号会被触发，允许各对象连接该信号
signal NodeProcessErrorOccur(info : String, node : SuntomeNodeBase)

#便利函数
func ErrorOccur(info : String, node : SuntomeNodeBase):
	NodeProcessErrorOccur.emit(info, node)


func clear_property():
	property_variable = VariableProp.new()
	time_check_map.clear()
	suntome_count = 0


func _ready() -> void:
	begin_node.position = Vector2(50,50)
	begin_node.is_transit_node = true
	sourou_node.position = Vector2(50,200)
	sourou_node.is_transit_node = true


static func root_path() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://").path_join("temp")
	return OS.get_executable_path().get_base_dir()


static func config_path() -> String:
	return root_path().path_join("config")



#将数据保存
func save():
	var filePath = root_path().path_join(SaveFile)
	var datastr = SuntomeSerialization.serialize(self)
	if "error" == datastr:
		printerr("save fail")
		return

	var file = FileAccess.open(filePath, FileAccess.WRITE)
	if null == file:
		printerr(FileAccess.get_open_error())
		return

	if not file.store_string(datastr):
		printerr("save file write fail")

	file.close()
	print("save success")
	pass


#从本地读取数据
func load_from_disc():
	var filePath = root_path().path_join(SaveFile)

	if not DirAccess.open(root_path()).file_exists(filePath):
		print("save file not find")
		return

	var file = FileAccess.open(filePath, FileAccess.READ)
	if null == file:
		printerr("无法打开文件，error code：", FileAccess.get_open_error())
		return

	var datastr = file.get_as_text()

	sound_object_contents.clear()
	select_pic_contents.clear()
	suntome_nodes.clear()
	begin_node = SuntomeNode.new_transit_node()
	sourou_node = SuntomeNode.new_transit_node()

	var errorstr = SuntomeSerialization.unserialize(self, datastr)
	if not errorstr.is_empty():
		push_error(errorstr)
		return


func now_time() -> float:
	return float(Time.get_ticks_msec()) / 1000.0
