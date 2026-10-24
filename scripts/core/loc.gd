extends Node
## EN default — international ship. VI optional.

signal language_changed(code: String)

const SUPPORTED := ["en", "vi"]
var code: String = "en"

var _t := {
	"en": {
		"game.title": "Aureole",
		"game.tag": "Stack the light. One more try.",
		"menu.play": "Play",
		"menu.best": "Best  %d",
		"menu.leave": "Leave",
		"hud.tap": "Tap",
		"hud.perfect": "Perfect",
		"hud.good": "Good",
		"over.title": "Fallen",
		"over.score": "Score  %d",
		"over.best": "Best  %d",
		"over.retry": "Again",
		"over.menu": "Menu",
	},
	"vi": {
		"game.title": "Aureole",
		"game.tag": "Xếp ánh sáng. Thêm một lần nữa.",
		"menu.play": "Chơi",
		"menu.best": "Cao nhất  %d",
		"menu.leave": "Thoát",
		"hud.tap": "Chạm",
		"hud.perfect": "Hoàn hảo",
		"hud.good": "Tốt",
		"over.title": "Rơi",
		"over.score": "Điểm  %d",
		"over.best": "Cao nhất  %d",
		"over.retry": "Lại",
		"over.menu": "Menu",
	},
}


func tr_key(key: String) -> String:
	var table: Dictionary = _t.get(code, _t["en"])
	if table.has(key):
		return str(table[key])
	return str(_t["en"].get(key, key))


func set_language(new_code: String) -> void:
	if new_code not in SUPPORTED:
		return
	code = new_code
	language_changed.emit(code)
