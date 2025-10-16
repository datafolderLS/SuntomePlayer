class_name ParamCtrl extends HBoxContainer

func set_text(text : String):
	get_node("Label").text = text

func container() -> HBoxContainer:
	return get_node("HBoxContainer")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
