extends TextureRect

func _process(delta: float) -> void:
	if null == texture:
		size = Vector2.ZERO
		return

	var psize = get_parent().size
	var tex_size = texture.get_size()
	var x_scale = tex_size.x / psize.x
	var y_scale = tex_size.y / psize.y
	var use_scale = max(x_scale, y_scale)
	size = tex_size / use_scale

	var anchor_off = (psize - size) * 0.5 / psize
	anchor_left = anchor_off.x
	anchor_top = anchor_off.y
	pass
