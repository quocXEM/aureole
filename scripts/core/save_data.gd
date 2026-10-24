extends Node

const PATH := "user://aureole.save"

var best: int = 0


func _ready() -> void:
	_load()


func note_score(score: int) -> void:
	if score > best:
		best = score
		_save()


func _save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_var({"best": best})


func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var data = f.get_var()
	if data is Dictionary:
		best = int(data.get("best", 0))
