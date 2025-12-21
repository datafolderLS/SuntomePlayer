extends Node2D

var _get_mouse_pos : Callable
var binded : bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	pass # Replace with function body.


func set_func(get_pos : Callable):
	_get_mouse_pos = get_pos
	binded = true
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not binded:
		return

	visible = Input.is_key_pressed(KEY_ALT)

	if visible :
		position = _get_mouse_pos.call()
	pass
