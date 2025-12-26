extends Tree

class_name FileTree

#文件树控件的拖动data数据为[path : String, Type, AssetType]

enum Type {
	Folder = 0,
	File = 1,
}

enum AssetType {
	Nothing = -1,     #什么都不是
	Sound = 0,     #音频文件
	Picture = 1,   #图像文件
	Subtitle = 2   #字幕文件
}

static var picture_icon = preload("res://editor/icon/picture_32.png")
static var sound_icon = preload("res://editor/icon/speaker_32.png")
static var subtitle_icon = preload("res://editor/icon/subtitle_32.png")


signal on_select_file_change(path : String, type : AssetType)

# const SurportPictureTypes = ["jpg", "png"]
# const SurportSoundTypes = ["mp3", "wav", "ogg"]

var _root_path : String


#返回一个FileTree控件，如果filePath不是合法路径，则返回一个空对象
static func new_tree(filePath : String) -> FileTree:
	var tree = preload("res://editor/base/file_tree.tscn").instantiate()

	if not filePath.is_absolute_path():
		if filePath.is_relative_path() :
			#将路径转换为绝对路径
			filePath = OS.get_executable_path().get_base_dir().path_join(filePath)
		else:
			tree.create_item().set_text(0, "construct error, not a legal path")
			return tree

	#print(filePath)
	var dir = DirAccess.open(filePath)
	if null == dir:
		tree.create_item().set_text(0, dir.tr("construct error, path: \"{0}\" not exist").format(Utility.cut_file_path(filePath)))
		return tree

	tree._root_path = filePath
	tree._refresh_path_list()
	# var splitArray = filePath.rsplit("/", true, 1)
	# tree.create_item().set_text(0, splitArray[1])

	# _folder_scan(filePath, func (path : String, type : Type) :
	# 	match type:
	# 		Type.Folder:
	# 			print("文件夹" + path)
	# 			var node = tree.add_or_find_node(path)
	# 			node.set_metadata(0, [path, Type.Folder, AssetType.Nothing])
	# 		Type.File:
	# 			print("文件" + path)
	# 			var suffixCheck = path.rsplit(".", true, 1)
	# 			if suffixCheck[1].to_lower() in GlobalSetting.SurportPictureTypes:
	# 				var node = tree.add_or_find_node(path)
	# 				node.set_icon(0, picture_icon)
	# 				node.set_metadata(0, [path, Type.File, AssetType.Picture])
	# 				pass
	# 			elif suffixCheck[1].to_lower() in GlobalSetting.SurportSoundTypes:
	# 				var node = tree.add_or_find_node(path)
	# 				node.set_icon(0, sound_icon)
	# 				node.set_metadata(0, [path, Type.File, AssetType.Sound])
	# 				pass
	# 			elif suffixCheck[1].to_lower() in SubtitleData.SupportSubtitleTypes.keys():
	# 				var node = tree.add_or_find_node(path)
	# 				node.set_icon(0, subtitle_icon)
	# 				node.set_metadata(0, [path, Type.File, AssetType.Subtitle])
	# 				pass
	# 	pass
	# )

	return tree


func _ready():
	item_selected.connect(func():
		print("")
	)
	cell_selected.connect(func():
		var meta = get_selected().get_metadata(0)
		if null == meta:
			return

		if Type.Folder == meta[1]:
			return

		# print(Utility.cut_file_path(meta[0]), meta[2])
		on_select_file_change.emit(Utility.cut_file_path(meta[0]), meta[2])
	)

	%Button_fresh.pressed.connect(_refresh_path_list)
	pass


#在树中添加一个路径为path的节点，如果存在就返回已有的节点
func add_or_find_node(path : String) -> TreeItem:
	if not path.contains(_root_path) :
		print("path: " + path + "not contains: " + _root_path)
		return null

	if path == _root_path:
		return null

	path = path.trim_prefix(_root_path)
	var pathlist := path.split("/", false)

	var parent = get_root()

	for part in pathlist:
		var findExist = false
		for item in parent.get_children():
			var text = item.get_text(0)
			if text == part:
				parent = item
				findExist = true
				break

		if findExist:
			continue

		parent = parent.create_child()
		parent.set_text(0, part)
		pass

	return parent


# static func _it_treeitem_child(item : TreeItem, cb : Callable):
# 	# var num = item.get_child_count();
# 	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _get_drag_data(_at_position: Vector2) -> Variant:
	var it = get_selected()
	if null == it:
		return null
	var preview = _drag_preview(it)
	if null == preview:
		return null
	set_drag_preview(preview)
	return it.get_metadata(0)


static func _drag_preview(item : TreeItem) -> Control:
	var arry = item.get_metadata(0)

	if null == arry:
		return null

	var _path : String = arry[0]
	var type = arry[1]
	var ctrl = TextureRect.new()
	#var type : Type = item.get_metadata(1)
	match type:
		Type.File:
			var atype : AssetType = arry[2]
			match atype:
				AssetType.Sound:
					ctrl.set_texture(sound_icon)
					pass
				AssetType.Picture:
					ctrl.set_texture(picture_icon)
					pass
				AssetType.Subtitle:
					ctrl.set_texture(subtitle_icon)
					pass
				_:
					return null
		Type.Folder:
			ctrl = Label.new()
			ctrl.text = Utility.cut_file_path(arry[0])
		_:
			return null
	var container = CenterContainer.new()
	container.add_child(ctrl)
	container.use_top_left = true;
	return container


#遍历path路径下的所有文件夹和文件，并调用callback函数，callback的参数为（path，Type）
static func _folder_scan(path : String, callback : Callable):
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				var sub_path = path + "/" + file_name
				callback.call(sub_path, Type.Folder)
				_folder_scan(sub_path, callback)
			else:
				var _name = path + "/" + file_name
				callback.call(_name, Type.File)
			file_name = dir.get_next()
		dir.list_dir_end()


#遍历path路径下的所有文件夹和文件，并调用callback函数，callback的参数为（path，Type），如果do_recursion为true则会遍历子目录
static func scan_folder(path : String, callback : Callable, do_recursion : bool = false):
	path = Utility.relative_to_full(path)
	if do_recursion:
		_folder_scan(path, callback)
		return
	else:
		var dir := DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					var _name = path + "/" + file_name
					callback.call(_name, Type.File)
				file_name = dir.get_next()
			dir.list_dir_end()


#刷新文件路径
func _refresh_path_list():
	clear()
	var splitArray = _root_path.rsplit("/", true, 1)
	create_item().set_text(0, splitArray[1])

	_folder_scan(_root_path, func (path : String, type : Type) :
		match type:
			Type.Folder:
				print("文件夹" + path)
				var node = add_or_find_node(path)
				node.set_metadata(0, [path, Type.Folder, AssetType.Nothing])
			Type.File:
				print("文件" + path)
				var suffixCheck = path.rsplit(".", true, 1)
				if suffixCheck[1].to_lower() in GlobalSetting.SurportPictureTypes:
					var node = add_or_find_node(path)
					node.set_icon(0, picture_icon)
					node.set_metadata(0, [path, Type.File, AssetType.Picture])
					pass
				elif suffixCheck[1].to_lower() in GlobalSetting.SurportSoundTypes:
					var node = add_or_find_node(path)
					node.set_icon(0, sound_icon)
					node.set_metadata(0, [path, Type.File, AssetType.Sound])
					pass
				elif suffixCheck[1].to_lower() in SubtitleData.SupportSubtitleTypes.keys():
					var node = add_or_find_node(path)
					node.set_icon(0, subtitle_icon)
					node.set_metadata(0, [path, Type.File, AssetType.Subtitle])
					pass
		pass
	)
	pass
