class_name SuntomeSPicContent extends VBoxContainer

#该content关联的SuntomeNode对象
var ref_suntome_node : SuntomeSelectPictNode

#容纳该对象的StateNode
var parent_node : StateNode

#显示调用来更新节点信息(node : StateNode) -> void
var update_node_line_info : Callable

#用来删除节点和节点连接(node : StateNode, other : SuntomeNodeBase) -> void
var delete_node_line : Callable

func _ready() -> void:
	pass # Replace with function body.


static func create_ctt_from_pic_node(
		parent : StateNode,
		node : SuntomeSelectPictNode,
		update_line_func : Callable,
		delete_line_func : Callable
		) -> SuntomeSPicContent:
	if null == node:
		return

	var ctt = preload("res://editor/suntome_s_pic_content.tscn").instantiate()
	ctt.ref_suntome_node = node
	ctt.set_select_picture_content(node.usedSelectPic)
	ctt.parent_node = parent
	ctt.update_node_line_info = update_line_func
	ctt.delete_node_line = delete_line_func
	#将控件加入父控件
	parent.get_container().add_child(ctt)
	return ctt


#该函数只应当在构造时调用一次
func set_select_picture_content(ctt : SelectPicContent):
	if ref_suntome_node.usedSelectPic.texture_change_sig.is_connected(_select_pic_change_pic):
		return

	get_node("%texture_path").text = ctt.name
	get_node("%texture_path").set("theme_override_colors/font_color", Color.WHITE)
	ctt.texture_change_sig.connect(_select_pic_change_pic)
	ctt.name_changed_sig.connect(_select_pic_name_change)
	ctt.before_delete_sig.connect(_select_pic_before_delete)

	if ctt.usedTexturePath.is_empty():
		%texture.texture = null
	else:
		%texture.texture = TextureCenter.get_picture(Utility.relative_to_full(ctt.usedTexturePath))

	ctt.button_name_change_signal.connect(
		func(_prename : String, _now_name : String):
			# req_line_change.emit(prename, now_name)
			update_node_line_info.call(parent_node)

	)
	ctt.button_before_delete_signal.connect(
		func(bname : String):
			# req_line_delete.emit(bname)
			_process_line_delete(bname)
	)


#拖拽相关函数
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_STRING and SuntomeGlobal.sound_object_contents.keys().has(data):
		return true
	return false


func _drop_data(_at_position: Vector2, data: Variant):
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


func set_sound_obj_content_name(objname : String):
	if null != ref_suntome_node.usedSoundObject:
		ref_suntome_node.usedSoundObject.name_changed_sig.disconnect(_soundobj_name_change)
		ref_suntome_node.usedSoundObject.before_delete_sig.disconnect(_soundobj_delete_before)

	ref_suntome_node.usedSoundObject = SuntomeGlobal.sound_object_contents[objname]
	_bind_soundobjcontent(ref_suntome_node.usedSoundObject)
	pass


func _select_pic_name_change(ctt : SelectPicContent):
	get_node("%texture_path").text = ctt.name


func _select_pic_before_delete(ctt : SelectPicContent):
	if ctt != ref_suntome_node.usedSelectPic:
		return

	parent_node.get_panel().node_require_delete(parent_node)
	# req_delete.emit(self)
	pass


func _select_pic_change_pic(ctt : SelectPicContent):
	if ctt.usedTexturePath.is_empty():
		return
	%texture.texture = TextureCenter.get_picture(Utility.relative_to_full(ctt.usedTexturePath))


func _process_line_delete(bname : String):
	var spctt : SelectPicContent = ref_suntome_node.usedSelectPic
	if not spctt.nextNodes_button_to_uid.has(bname):
		return

	var toNodeUid = spctt.nextNodes_button_to_uid[bname]
	var nextNode = ref_suntome_node.nextNodes[toNodeUid]
	delete_node_line.call(parent_node, nextNode)


#和PlayNodeEditor联动的函数
#返回用户拖动节点连线时显示的线条信息
func get_drag_line_info() -> String:
	var names : Array = ref_suntome_node.usedSelectPic.get_unused_names()
	if names.is_empty():
		return "no selection"
	return names[0]


#当连线连接时，判断是否可以连接
func line_connect_check() -> bool:
	var names : Array = ref_suntome_node.usedSelectPic.get_unused_names()
	if names.is_empty():
		return false
	return true


#处理和target相连的逻辑，仅当line_connect_check()返回true时才会执行该函数
func process_node_connect(target : SuntomeNodeBase):
	ref_suntome_node.nextNodes.set(target.uid, target)
	var bname = get_drag_line_info()
	ref_suntome_node.usedSelectPic.nextNodes_button_to_uid.set(bname, target.uid)


#处理和target断开连接的逻辑
func process_node_disconnect(target : SuntomeNodeBase):
	ref_suntome_node.nextNodes.erase(target.uid)
	ref_suntome_node.usedSelectPic.remove_uid(target.uid)


#获取该节点和其他节点的连线文本信息，该函数返回一个可调用的函数对象(other_node : SuntomeNodeBase) -> String
func get_connect_line_lable() -> Callable:
	var reversekey = ref_suntome_node.usedSelectPic.get_reversed_node_to_value_dict()
	return func(other_node : SuntomeNodeBase) -> String:
		var _uid = other_node.uid
		return reversekey[_uid]


#playnodeeditor会调用该函数来请求在参数栏显示节点参数
func show_node_param(parent : Container):
	for c in parent.get_children():
		parent.remove_child(c)

