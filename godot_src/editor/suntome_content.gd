class_name SuntomContent extends VBoxContainer
#负责处理SuntomeNode对象信息的gui类

#该content关联的SuntomeNode对象
var ref_suntome_node : SuntomeNode

#容纳该对象的StateNode
var parent_node : StateNode

#显示调用来更新节点信息(node : StateNode) -> void
var update_node_line_info : Callable

static var param_panel : Control = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


static func Create(parent : StateNode, node : SuntomeNode, update_line_func : Callable) -> SuntomContent:
	var rel = preload("res://editor/suntome_content.tscn").instantiate()
	rel.parent_node = parent
	rel.set_suntome_node(node)
	parent.get_container().add_child(rel)
	rel.update_node_line_info = update_line_func
	return rel


func set_suntome_node(node : SuntomeNode):
	if null == node:
		return

	ref_suntome_node = node
	if null == node.usedSoundObject:
		get_node("%sound_path").text = "no sound obj yet"
		get_node("%sound_path").set("theme_override_colors/font_color", Color.RED)
	else:
		_bind_soundobjcontent(node.usedSoundObject)

	if node.usedTexturePath.is_empty():
		get_node("%texture_path").text = "no texture yet"
		get_node("%texture_path").set("theme_override_colors/font_color", Color.RED)
	else:
		# get_node("%texture_path").text = node.usedTexturePath
		# get_node("%texture_path").set("theme_override_colors/font_color", Color.WHITE)
		set_picture_path(node.usedTexturePath)



#拖拽相关函数
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if null == ref_suntome_node:
		print("critical error")
		return false

	if typeof(data) == TYPE_ARRAY and data.size() <= 2:
		return false
		# return SuntomeGlobal.select_pic_contents.keys().has(data[0])

	if typeof(data) == TYPE_ARRAY and data[2] == FileTree.AssetType.Picture:
		return true

	if typeof(data) == TYPE_ARRAY and data[2] == FileTree.AssetType.Sound:
		return true

	if typeof(data) == TYPE_STRING and SuntomeGlobal.sound_object_contents.keys().has(data):
		return true
	return false


func _drop_data(_at_position: Vector2, data: Variant):
	if typeof(data) == TYPE_ARRAY and data.size() < 2:
		# if SuntomeGlobal.select_pic_contents.keys().has(data[0]):
		# 	set_select_picture_content(SuntomeGlobal.select_pic_contents[data[0]])
		return

	if typeof(data) == TYPE_ARRAY and data[2] == FileTree.AssetType.Picture:
		print(data)
		set_picture_path(data[0])

	if typeof(data) == TYPE_ARRAY and data[2] == FileTree.AssetType.Sound:
		print(data)
		set_sound_path(data[0])

	if typeof(data) == TYPE_STRING and SuntomeGlobal.sound_object_contents.keys().has(data):
		set_sound_obj_content_name(data)
	pass


func _bind_soundobjcontent(objcontent : SoundObjContent):
	get_node("%sound_path").text = objcontent.name
	get_node("%sound_path").set("theme_override_colors/font_color", Color.WHITE)
	#绑定信号
	objcontent.name_changed_sig.connect(_soundobj_name_change)
	objcontent.before_delete_sig.connect(_soundobj_delete_before)
	pass


func _soundobj_name_change(obj : SoundObjContent):
	if obj == ref_suntome_node.usedSoundObject:
		get_node("%sound_path").text = obj.name
	pass

func _soundobj_delete_before(obj : SoundObjContent):
	if obj != ref_suntome_node.usedSoundObject:
		return

	get_node("%sound_path").text = "no sound obj yet"
	get_node("%sound_path").set("theme_override_colors/font_color", Color.RED)
	ref_suntome_node.usedSoundObject = null
	pass


#绑定音频为音频对象
func set_sound_obj_content_name(objname : String):
	_clear_sound_obj_bind_if_exist()

	ref_suntome_node.usedSoundObject = SuntomeGlobal.sound_object_contents[objname]
	_bind_soundobjcontent(ref_suntome_node.usedSoundObject)
	pass


#绑定音频为音频文件
func set_sound_path(path : String):
	_clear_sound_obj_bind_if_exist()
	#构造一个临时的音频对象（音频对象不在SuntomeGlobal.sound_object_contents中
	path = Utility.cut_file_path(path)
	ref_suntome_node.usedSoundObject = SoundObjContent.make_temp_soundobj(path)
	_bind_soundobjcontent(ref_suntome_node.usedSoundObject)
	pass


func _clear_sound_obj_bind_if_exist():
	if null != ref_suntome_node.usedSoundObject:
		ref_suntome_node.usedSoundObject.name_changed_sig.disconnect(_soundobj_name_change)
		ref_suntome_node.usedSoundObject.before_delete_sig.disconnect(_soundobj_delete_before)


func set_picture_path(_path : String):
	var path = Utility.cut_file_path(_path)
	get_node("%texture_path").text = path
	get_node("%texture_path").set("theme_override_colors/font_color", Color.WHITE)
	ref_suntome_node.usedTexturePath = path
	%texture.texture = TextureCenter.get_picture(Utility.relative_to_full(path))


func _select_pic_name_change(ctt : SelectPicContent):
	get_node("%texture_path").text = ctt.name


func _select_pic_before_delete(_ctt : SelectPicContent):
	get_node("%texture_path").text = "no texture yet"
	get_node("%texture_path").set("theme_override_colors/font_color", Color.RED)
	%texture.texture = null
	ref_suntome_node.usedTexturePath = ""
	pass

func _select_pic_change_pic(ctt : SelectPicContent):
	if ctt.usedTexturePath.is_empty():
		return
	%texture.texture = TextureCenter.get_picture(Utility.relative_to_full(ctt.usedTexturePath))


#和PlayNodeEditor联动的函数
#返回用户拖动节点连线时显示的线条信息
func get_drag_line_info() -> String:
	var index = ref_suntome_node.get_unused_index()
	return String.num_int64(index)


#当连线连接时，判断是否可以连接
func line_connect_check() -> bool:
	return true


#和target相连，仅当line_connect_check()返回true时才会执行该函数
func process_node_connect(target : SuntomeNodeBase):
	ref_suntome_node.nextNodes.set(target.uid, target)

	var index = ref_suntome_node.get_unused_index()
	ref_suntome_node.nextNodes_index.set(target.uid, index)
	var avgchance = func():
		if ref_suntome_node.nextNodes_chance.size() == 0:
			return 1.0
		var sumv = ref_suntome_node.nextNodes_chance.values().reduce(
				func(accum, value):
					if typeof(value) == TYPE_FLOAT:
						return accum + value
					return accum
		)
		return sumv / ref_suntome_node.nextNodes_chance.size()
	ref_suntome_node.nextNodes_chance.set(target.uid, avgchance.call())
	ref_suntome_node.update_index_data()


#处理和target断开连接的逻辑
func process_node_disconnect(target : SuntomeNodeBase):
	ref_suntome_node.nextNodes.erase(target.uid)
	ref_suntome_node.nextNodes_chance.erase(target.uid)
	ref_suntome_node.nextNodes_index.erase(target.uid)
	ref_suntome_node.update_index_data()


#获取该节点和其他节点的连线文本信息，该函数返回一个可调用的函数对象(other_node : SuntomeNodeBase) -> String
func get_connect_line_lable() -> Callable:
	return func(other_node : SuntomeNodeBase) -> String:
		var _uid = other_node.uid
		var index = ref_suntome_node.nextNodes_index[_uid]
		return String.num_int64(index)


#playnodeeditor会调用该函数来请求在参数栏显示节点参数
func show_node_param(parent : Container):
	for c in parent.get_children():
		parent.remove_child(c)

	if null == param_panel:
		param_panel = preload("res://editor/suntome_content_param_panel.tscn").instantiate()

	param_panel.ob_item_selected_cb = func(id : int):
		ref_suntome_node.play_mode = id as Utility.RandomHelper.Method

	param_panel.cb_pressed_change_cb = func(value : bool):
		ref_suntome_node.is_suntome = value

	param_panel.button_normalization_cb = func():
		var chances = ref_suntome_node.nextNodes_chance.values()
		if chances.is_empty():
			return

		var total = 0.0
		for v in chances:
			if typeof(v) == TYPE_STRING:
				continue
			total += v

		if is_zero_approx(total):
			return

		for _uid in ref_suntome_node.nextNodes_chance:
			var pre = ref_suntome_node.nextNodes_chance[_uid]
			if typeof(pre) == TYPE_STRING:
				continue
			ref_suntome_node.nextNodes_chance[_uid] = pre / total
			pass

		_update_param_info(param_panel)

	param_panel.order_changed_cb = func(): _param_order_change()

	parent.add_child(param_panel)
	param_panel.show()

	_update_param_info(param_panel)
	#更新线条的显示信息
	update_node_line_info.call(parent_node)
	pass


#end（和PlayNodeEditor联动的函数）

func _update_param_info(panel : Control):
	ref_suntome_node.check_chance_index_data()
	var ctrllist = Array()
	var ctrlType = preload("res://editor/base/node_param_ctrl.tscn")

	for _uid in ref_suntome_node.nextNodes:
		var chance = ref_suntome_node.nextNodes_chance[_uid]
		var index = ref_suntome_node.nextNodes_index[_uid]
		var ctrl = ctrlType.instantiate()
		ctrl.set_value(chance)
		ctrl.set_index(index)
		ctrl.value_change.connect(
			func(_ctr : NodeParamCtrl):
				ref_suntome_node.nextNodes_chance[_uid] = _ctr.value()
				pass
		)
		ctrllist.append(ctrl)

	ctrllist.sort_custom(
		func(left : NodeParamCtrl, right : NodeParamCtrl):
			return left.index() < right.index()
	)

	panel.get_node("%DragSortControl").set_array(ctrllist)
	panel.get_node("%OB_type").select(ref_suntome_node.play_mode)
	param_panel.get_node("%CB_isSuntome").button_pressed = ref_suntome_node.is_suntome

	pass


func _param_order_change():
	var dragsortctrl = param_panel.get_node("%DragSortControl")
	var ctrllist = dragsortctrl.get_array()
	var indexchangemap : Dictionary = Dictionary()
	for i in range(1, ctrllist.size() + 1):
		indexchangemap.set(ctrllist[i-1].index(), i)

	for _uid in ref_suntome_node.nextNodes_index:
		var preIndex = ref_suntome_node.nextNodes_index[_uid]
		var newIndex = indexchangemap[preIndex]
		ref_suntome_node.nextNodes_index[_uid] = newIndex

	ref_suntome_node.update_index_data()
	_update_param_info(param_panel)
	#更新线条的显示信息
	update_node_line_info.call(parent_node)
	pass
