extends Node2D
## Aureole — international art-casual stack. Cut leftovers, Perfect juice, one more try.

const BASE_W := 300.0
const SLAB_H := 34.0
const PERFECT := 7.0
const SWING := 200.0
const DROP_SPEED := 1650.0
const COLORS := [
	Color(0.94, 0.84, 0.62),
	Color(0.9, 0.74, 0.58),
	Color(0.82, 0.72, 0.86),
	Color(0.7, 0.8, 0.84),
	Color(0.88, 0.8, 0.66),
	Color(0.93, 0.72, 0.64),
	Color(0.76, 0.84, 0.72),
]

@onready var world: Node2D = $World
@onready var camera: Camera2D = $Camera
@onready var score_l: Label = $UI/Score
@onready var combo_l: Label = $UI/Combo
@onready var hint_l: Label = $UI/Hint
@onready var flash_l: Label = $UI/Flash
@onready var over: PanelContainer = $UI/Over
@onready var over_title: Label = $UI/Over/VBox/Title
@onready var over_score: Label = $UI/Over/VBox/Score
@onready var over_best: Label = $UI/Over/VBox/Best
@onready var btn_retry: Button = $UI/Over/VBox/Retry
@onready var btn_menu: Button = $UI/Over/VBox/Menu
@onready var dim: ColorRect = $UI/Dim

var _slabs: Array = []
var _moving: Dictionary = {}
var _dropping := false
var _drop_y := 0.0
var _score := 0
var _combo := 0
var _alive := true
var _swing_t := 0.0
var _swing_speed := 1.45
var _color_i := 0
var _cam_target_y := 900.0
var _hint_done := false
var _guide: Line2D
var _new_best := false


func _ready() -> void:
	btn_retry.pressed.connect(_restart)
	btn_menu.pressed.connect(func() -> void:
		AudioBus.play_ui()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	over.visible = false
	dim.visible = false
	flash_l.modulate.a = 0.0
	combo_l.modulate.a = 0.0
	var atm: Node2D = (load("res://scripts/fx/atmosphere.gd") as GDScript).new()
	add_child(atm)
	move_child(atm, 0)
	_guide = Line2D.new()
	_guide.width = 1.0
	_guide.default_color = Color(0.95, 0.9, 0.8, 0.08)
	_guide.z_index = -1
	_guide.add_point(Vector2(360, -4000))
	_guide.add_point(Vector2(360, 4000))
	world.add_child(_guide)
	_refresh_loc()
	Loc.language_changed.connect(func(_c): _refresh_loc())
	_start_run()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.4)


func _refresh_loc() -> void:
	hint_l.text = Loc.tr_key("hud.tap")
	over_title.text = Loc.tr_key("over.title")
	btn_retry.text = Loc.tr_key("over.retry")
	btn_menu.text = Loc.tr_key("over.menu")
	_paint_hud()


func _start_run() -> void:
	for c in world.get_children():
		if c == _guide:
			continue
		c.queue_free()
	_slabs.clear()
	_moving = {}
	_dropping = false
	_score = 0
	_combo = 0
	_alive = true
	_new_best = false
	_swing_t = 0.0
	_swing_speed = 1.45
	_color_i = 0
	_hint_done = false
	hint_l.visible = true
	hint_l.modulate.a = 0.5
	over.visible = false
	dim.visible = false
	_cam_target_y = 900.0
	camera.position = Vector2(360, _cam_target_y)
	camera.zoom = Vector2.ONE
	_spawn_slab(360.0, 1100.0, BASE_W, false)
	_spawn_moving()
	_paint_hud()
	_pop_score()


func _restart() -> void:
	AudioBus.play_ui()
	_start_run()


func _paint_hud() -> void:
	score_l.text = str(_score)
	over_score.text = Loc.tr_key("over.score") % _score
	var best_txt := Loc.tr_key("over.best") % SaveData.best
	if _new_best:
		best_txt = Loc.tr_key("over.new_best") % SaveData.best
	over_best.text = best_txt


func _spawn_slab(x: float, y: float, w: float, moving: bool) -> Dictionary:
	var body := Node2D.new()
	body.position = Vector2(x, y)
	world.add_child(body)
	var col := COLORS[_color_i % COLORS.size()]
	# Soft contact shadow
	var sh := Polygon2D.new()
	var hw := w * 0.5
	var hh := SLAB_H * 0.5
	sh.polygon = PackedVector2Array([
		Vector2(-hw + 4, hh - 2), Vector2(hw - 4, hh - 2), Vector2(hw + 6, hh + 10), Vector2(-hw - 6, hh + 10),
	])
	sh.color = Color(0, 0, 0, 0.22)
	body.add_child(sh)
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh),
	])
	poly.color = col
	body.add_child(poly)
	var hi := Polygon2D.new()
	hi.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, -hh + 5), Vector2(-hw, -hh + 5),
	])
	hi.color = Color(1, 1, 1, 0.2)
	body.add_child(hi)
	var edge := Line2D.new()
	edge.width = 1.0
	edge.default_color = Color(1, 1, 1, 0.12)
	edge.closed = true
	edge.add_point(Vector2(-hw, -hh))
	edge.add_point(Vector2(hw, -hh))
	edge.add_point(Vector2(hw, hh))
	edge.add_point(Vector2(-hw, hh))
	body.add_child(edge)
	var d := {"node": body, "x": x, "w": w, "y": y, "poly": poly, "sh": sh, "hi": hi, "edge": edge, "col": col}
	if moving:
		body.modulate.a = 0.92
		_moving = d
	else:
		_slabs.append(d)
		_color_i += 1
	return d


func _spawn_moving() -> void:
	var top: Dictionary = _slabs.back()
	var y := float(top.y) - SLAB_H - 2.0
	_spawn_slab(360.0 - SWING, y, float(top.w), true)
	_swing_t = randf() * TAU
	_dropping = false


func _process(delta: float) -> void:
	if not _alive:
		return
	camera.position.y = lerpf(camera.position.y, _cam_target_y, 1.0 - exp(-delta * 5.0))
	if _dropping and not _moving.is_empty():
		_drop_y += DROP_SPEED * delta
		var target_y := float(_slabs.back().y) - SLAB_H
		var ny := minf(_drop_y, target_y)
		_moving.node.position.y = ny
		_moving.y = ny
		if ny >= target_y - 0.5:
			_resolve_land()
		return
	if _moving.is_empty():
		return
	_swing_t += delta * _swing_speed
	var x := 360.0 + sin(_swing_t) * SWING
	_moving.node.position.x = x
	_moving.x = x
	if not _hint_done:
		hint_l.modulate.a = 0.28 + 0.28 * absf(sin(_swing_t * 2.2))


func _unhandled_input(event: InputEvent) -> void:
	if not _alive:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_drop()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_try_drop()
	elif event is InputEventScreenTouch and event.pressed:
		_try_drop()


func _try_drop() -> void:
	if _dropping or _moving.is_empty():
		return
	_dropping = true
	_drop_y = float(_moving.y)
	_hint_done = true
	hint_l.visible = false
	AudioBus.play_tap()


func _resolve_land() -> void:
	_dropping = false
	var top: Dictionary = _slabs.back()
	var mx: float = _moving.x
	var mw: float = _moving.w
	var tx: float = top.x
	var tw: float = top.w
	var left := maxf(mx - mw * 0.5, tx - tw * 0.5)
	var right := minf(mx + mw * 0.5, tx + tw * 0.5)
	var overlap := right - left
	if overlap <= 3.5:
		_game_over()
		return

	# Leftover falls — signature Stack juice
	var m_left := mx - mw * 0.5
	var m_right := mx + mw * 0.5
	if m_left < left - 0.5:
		_spawn_fall(m_left, left, float(_moving.y), _moving.col, -1.0)
	if m_right > right + 0.5:
		_spawn_fall(right, m_right, float(_moving.y), _moving.col, 1.0)

	var new_x := (left + right) * 0.5
	var new_w := overlap
	var offset := absf(mx - tx)
	var perfect := offset <= PERFECT

	# Perfect restores a whisper of width (international Stack feel)
	if perfect:
		new_w = minf(BASE_W, new_w + 4.0)
		new_x = tx

	_moving.x = new_x
	_moving.w = new_w
	_moving.y = float(top.y) - SLAB_H
	_moving.node.position = Vector2(new_x, _moving.y)
	_moving.node.modulate.a = 1.0
	_resize_poly(_moving)
	_squash(_moving.node)
	_slabs.append(_moving)
	_moving = {}
	_color_i += 1

	if perfect:
		_combo += 1
		_score += int(12 + _combo * 6)
		_flash(Loc.tr_key("hud.perfect"), Color(0.98, 0.92, 0.72, 1))
		AudioBus.play_perfect()
		_punch(1.05)
		_burst(Vector2(new_x, float(top.y) - SLAB_H))
		_ring_flash(Vector2(new_x, float(top.y) - SLAB_H), new_w)
	else:
		_combo = 0
		_score += 4 + int(new_w / 36.0)
		_flash(Loc.tr_key("hud.good"), Color(0.9, 0.86, 0.8, 0.75))
		AudioBus.play_land()

	_swing_speed = minf(2.9, _swing_speed + 0.045)
	_cam_target_y = float(_slabs.back().y) - 440.0
	_paint_hud()
	_pop_score()
	_spawn_moving()


func _spawn_fall(x0: float, x1: float, y: float, col: Color, dir: float) -> void:
	var w := x1 - x0
	if w < 2.0:
		return
	var body := Node2D.new()
	body.position = Vector2((x0 + x1) * 0.5, y)
	world.add_child(body)
	var hw := w * 0.5
	var hh := SLAB_H * 0.5
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh),
	])
	poly.color = col
	body.add_child(poly)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(body, "position", body.position + Vector2(dir * randf_range(80, 140), 420), 0.55).set_ease(Tween.EASE_IN)
	tw.tween_property(body, "rotation", dir * randf_range(0.6, 1.4), 0.55)
	tw.tween_property(body, "modulate:a", 0.0, 0.55)
	tw.chain().tween_callback(body.queue_free)


func _resize_poly(d: Dictionary) -> void:
	var hw := float(d.w) * 0.5
	var hh := SLAB_H * 0.5
	d.poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh),
	])
	d.sh.polygon = PackedVector2Array([
		Vector2(-hw + 4, hh - 2), Vector2(hw - 4, hh - 2), Vector2(hw + 6, hh + 10), Vector2(-hw - 6, hh + 10),
	])
	d.hi.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, -hh + 5), Vector2(-hw, -hh + 5),
	])
	var edge: Line2D = d.edge
	edge.clear_points()
	edge.add_point(Vector2(-hw, -hh))
	edge.add_point(Vector2(hw, -hh))
	edge.add_point(Vector2(hw, hh))
	edge.add_point(Vector2(-hw, hh))


func _squash(n: Node2D) -> void:
	n.scale = Vector2(1.06, 0.9)
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector2.ONE, 0.14).set_ease(Tween.EASE_OUT)


func _pop_score() -> void:
	score_l.scale = Vector2(1.12, 1.12)
	var tw := create_tween()
	tw.tween_property(score_l, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)


func _flash(text: String, col: Color) -> void:
	flash_l.text = text
	flash_l.modulate = col
	flash_l.scale = Vector2(0.85, 0.85)
	combo_l.text = ("×%d" % _combo) if _combo > 1 else ""
	combo_l.modulate.a = 1.0 if _combo > 1 else 0.0
	var tw := create_tween()
	tw.tween_property(flash_l, "scale", Vector2.ONE, 0.12)
	tw.parallel().tween_property(flash_l, "modulate:a", 0.0, 0.6).from(1.0)
	if _combo > 1:
		create_tween().tween_property(combo_l, "modulate:a", 0.0, 0.75).from(1.0)


func _punch(scale: float) -> void:
	var tw := create_tween()
	tw.tween_property(camera, "zoom", Vector2(scale, scale), 0.05)
	tw.tween_property(camera, "zoom", Vector2.ONE, 0.14)


func _burst(at: Vector2) -> void:
	for i in 14:
		var p := Polygon2D.new()
		var r := 2.0 + randf() * 3.5
		p.polygon = PackedVector2Array([Vector2(-r, -r), Vector2(r, -r), Vector2(r, r), Vector2(-r, r)])
		p.color = COLORS[_color_i % COLORS.size()]
		p.position = at + Vector2(randf_range(-24, 24), randf_range(-10, 6))
		world.add_child(p)
		var dir := Vector2(randf_range(-1, 1), randf_range(-1.4, -0.2)).normalized() * randf_range(50, 140)
		var tw := create_tween()
		tw.tween_property(p, "position", p.position + dir, 0.4)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.4)
		tw.tween_callback(p.queue_free)


func _ring_flash(at: Vector2, w: float) -> void:
	var ring := Node2D.new()
	ring.position = at
	world.add_child(ring)
	var r0 := w * 0.35
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(0.98, 0.92, 0.7, 0.7)
	for i in 33:
		var a := TAU * float(i) / 32.0
		line.add_point(Vector2(cos(a), sin(a)) * r0)
	ring.add_child(line)
	var tw := create_tween()
	tw.tween_property(ring, "scale", Vector2(1.6, 1.6), 0.35)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.35)
	tw.tween_callback(ring.queue_free)


func _game_over() -> void:
	_alive = false
	if not _moving.is_empty() and is_instance_valid(_moving.node):
		var n: Node2D = _moving.node
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(n, "position:y", n.position.y + 480.0, 0.5).set_ease(Tween.EASE_IN)
		tw.tween_property(n, "rotation", randf_range(-0.5, 0.5), 0.5)
		tw.tween_property(n, "modulate:a", 0.0, 0.5)
	AudioBus.play_fail()
	_new_best = _score > SaveData.best
	SaveData.note_score(_score)
	_paint_hud()
	dim.visible = true
	dim.modulate.a = 0.0
	over.visible = true
	over.modulate.a = 0.0
	var tw2 := create_tween()
	tw2.tween_property(dim, "modulate:a", 1.0, 0.3)
	tw2.parallel().tween_property(over, "modulate:a", 1.0, 0.35)
