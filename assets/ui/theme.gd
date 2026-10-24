extends Node


func _ready() -> void:
	get_tree().root.theme = _build()


func _font(path: String) -> FontFile:
	if not FileAccess.file_exists(path):
		return null
	var f := FontFile.new()
	if f.load_dynamic_font(path) != OK:
		return null
	return f


func _build() -> Theme:
	var theme := Theme.new()
	var reg := _font("res://assets/fonts/CormorantGaramond-Regular.ttf")
	var bold := _font("res://assets/fonts/CormorantGaramond-SemiBold.ttf")
	if reg:
		theme.default_font = reg
		theme.default_font_size = 24
	var ink := Color(0.12, 0.1, 0.09, 1)
	var cream := Color(0.96, 0.93, 0.88, 0.95)
	var line := Color(0.2, 0.16, 0.12, 0.45)
	var n := _box(cream, line, 1, 28, 18)
	var h := _box(Color(0.98, 0.96, 0.92, 1), Color(0.15, 0.12, 0.1, 0.7), 1, 28, 18)
	theme.set_stylebox("normal", "Button", n)
	theme.set_stylebox("hover", "Button", h)
	theme.set_stylebox("pressed", "Button", n)
	theme.set_stylebox("focus", "Button", h)
	theme.set_color("font_color", "Button", ink)
	theme.set_color("font_hover_color", "Button", ink)
	theme.set_font_size("font_size", "Button", 26)
	if bold:
		theme.set_font("font", "Button", bold)
	theme.set_color("font_color", "Label", cream)
	if reg:
		theme.set_font("font", "Label", reg)
	var panel := _box(Color(0.96, 0.93, 0.88, 0.92), Color(0.2, 0.16, 0.12, 0.2), 1, 22, 18)
	theme.set_stylebox("panel", "PanelContainer", panel)
	var ghost := StyleBoxEmpty.new()
	theme.set_type_variation("GhostButton", "Button")
	theme.set_stylebox("normal", "GhostButton", ghost)
	theme.set_stylebox("hover", "GhostButton", ghost)
	theme.set_stylebox("pressed", "GhostButton", ghost)
	theme.set_stylebox("focus", "GhostButton", ghost)
	theme.set_color("font_color", "GhostButton", Color(0.94, 0.9, 0.84, 0.45))
	theme.set_color("font_hover_color", "GhostButton", Color(0.96, 0.93, 0.88, 0.95))
	theme.set_font_size("font_size", "GhostButton", 16)
	if reg:
		theme.set_font("font", "GhostButton", reg)
	return theme


func _box(bg: Color, border: Color, bw: int, pad_h: int, pad_v: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(3)
	s.content_margin_left = pad_h
	s.content_margin_right = pad_h
	s.content_margin_top = pad_v * 0.55
	s.content_margin_bottom = pad_v * 0.55
	return s
