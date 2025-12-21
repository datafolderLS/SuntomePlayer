class_name localization_center extends Node

signal LocalChanged()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		LocalChanged.emit()