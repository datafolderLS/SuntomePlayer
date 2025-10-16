extends Control

@export var checkValue = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_node("Button").pressed.connect(_test)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _test():
	print("test")
	var a = SuntomeGlobal.sound_object_contents.values()
	if a.is_empty():
		return

	a = a[0]
	if not a is SoundObjContent:
		print("critical error")
		return

	checkValue = a.make_soundobject()
	pass
