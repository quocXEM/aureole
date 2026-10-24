extends Node2D
## Aureole — addictive stack loop. Tap to drop. Perfect = combo juice.

const BASE_W := 280.0
const SLAB_H := 36.0
const PERFECT := 8.0
const SWING := 210.0
const DROP_SPEED := 1400.0
const COLORS := [
	Color(0.93, 0.82, 0.58),
	Color(0.88, 0.72, 0.55),
	Color(0.78, 0.68, 0.82),
	Color(0.68, 0.78, 0.82),
	Color(0.85, 0.78, 0.62),
	Color(0.92, 0.7, 0.62),
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
@onready var vignette: ColorRect = $UI/Vignette

var _slabs: Array = [] # {node, x, w, y}
var _moving: Dictionary = {}
var _dropping := false
var _drop_y := 0.0
var _score := 0
var _combo := 0
var _alive := true
var _swing_t := 0.0
var _swing_speed := 1.55
var _color_i := 0
var _cam_target_y := 640.0
var _hint_done := false


func _ready() -> void:
	btn_retry.pressed.connect(_restart)
	btn_menu.pressed.connect(func() -> void:
		AudioBus.play_ui()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	over.visible = false
	flash_l.modulate.a = 0.0
	combo_l.modulate.a = 0.0
	_refresh_loc()
	Loc.language_changed.connect(func(_c): _refresh_loc())
	_start_run()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)


func _refresh_loc() -> void:
	hint_l.text = Loc.tr_key("hud.tap")
	over_title.text = Loc.tr_key("over.title")
	btn_retry.text = Loc.tr_key("over.retry")
	btn_menu.text = Loc.tr_key("over.menu")
	_paint_hud()


func _start_run() -> void:
	for c in world.get_children():
		c.queue_free()
	_slabs.clear()
	_moving = {}
	_dropping = false
	_score = 0
	_combo = 0
	_alive = true
	_swing_t = 0.0
	_swing_speed = 1.55
	_color_i = 0
	_hint_done = false
	hint_l.visible = true
	hint_l.modulate.a = 0.55
	over.visible = false
	_cam_target_y = 900.0
	camera.position = Vector2(360, _cam_target_y)
	# Base slab
	_spawn_slab(360.0, 1100.0, BASE_W, false)
	_spawn_moving()
	_paint_hud()


func _restart() -> void:
	AudioBus.play_ui()
	_start_run()


func _paint_hud() -> void:
	score_l.text = str(_score)
	over_score.text = Loc.tr_key("over.score") % _score
	over_best.text = Loc.tr_key("over.best") % SaveData.best


func _spawn_slab(x: float, y: float, w: float, moving: bool) -> Dictionary:
	var body := Node2D.new()
	body.position = Vector2(x, y)
	world.add_child(body)
	var poly := Polygon2D.new()
	var hw := w * 0.5
	var hh := SLAB_H * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh),
	])
	poly.color = COLORS[_color_i % COLORS.size()]
	body.add_child(poly)
	# Soft top highlight
	var hi := Polygon2D.new()
	hi.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, -hh + 6), Vector2(-hw, -hh + 6),
	])
	hi.color = Color(1, 1, 1, 0.18)
	body.add_child(hi)
	var d := {"node": body, "x": x, "w": w, "y": y, "poly": poly}
	if moving:
		_moving = d
	else:
		_slabs.append(d)
		_color_i += 1
	return d


func _spawn_moving() -> void:
	var top: Dictionary = _slabs.back()
	var y := float(top.y) - SLAB_H
	_spawn_slab(360.0 - SWING, y, float(top.w), true)
	_swing_t = 0.0
	_dropping = false


func _process(delta: float) -> void:
	if not _alive:
		return
	# Camera ease
	camera.position.y = lerpf(camera.position.y, _cam_target_y, 1.0 - exp(-delta * 4.0))
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
	# Pulse hint
	if not _hint_done:
		hint_l.modulate.a = 0.35 + 0.25 * absf(sin(_swing_t * 2.0))


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
	if overlap <= 4.0:
		_game_over()
		return
	var new_x := (left + right) * 0.5
	var new_w := overlap
	var offset := absf(mx - tx)
	var perfect := offset <= PERFECT
	# Update moving piece into placed slab
	_moving.x = new_x
	_moving.w = new_w
	_moving.y = float(top.y) - SLAB_H
	_moving.node.position = Vector2(new_x, _moving.y)
	_resize_poly(_moving)
	_slabs.append(_moving)
	_moving = {}
	_color_i += 1

	if perfect:
		_combo += 1
		_score += int(10 + _combo * 5)
		_flash(Loc.tr_key("hud.perfect"), Color(0.95, 0.9, 0.7, 1))
		AudioBus.play_perfect()
		_punch(1.04)
		_burst(Vector2(new_x, float(top.y) - SLAB_H))
	else:
		_combo = 0
		_score += 5 + int(new_w / 40.0)
		_flash(Loc.tr_key("hud.good"), Color(0.85, 0.82, 0.78, 0.85))
		AudioBus.play_land()

	_swing_speed = minf(2.8, _swing_speed + 0.04)
	_cam_target_y = float(_slabs.back().y) - 420.0
	_paint_hud()
	_spawn_moving()


func _resize_poly(d: Dictionary) -> void:
	var hw := float(d.w) * 0.5
	var hh := SLAB_H * 0.5
	var poly: Polygon2D = d.poly
	poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh),
	])
	# Highlight child
	if d.node.get_child_count() > 1:
		var hi: Polygon2D = d.node.get_child(1)
		hi.polygon = PackedVector2Array([
			Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, -hh + 6), Vector2(-hw, -hh + 6),
		])


func _flash(text: String, col: Color) -> void:
	flash_l.text = text
	flash_l.modulate = col
	combo_l.text = ("×%d" % _combo) if _combo > 1 else ""
	combo_l.modulate.a = 1.0 if _combo > 1 else 0.0
	var tw := create_tween()
	tw.tween_property(flash_l, "modulate:a", 0.0, 0.55).from(1.0)
	if _combo > 1:
		create_tween().tween_property(combo_l, "modulate:a", 0.0, 0.7).from(1.0)


func _punch(scale: float) -> void:
	var tw := create_tween()
	tw.tween_property(camera, "zoom", Vector2(scale, scale), 0.06)
	tw.tween_property(camera, "zoom", Vector2.ONE, 0.12)


func _burst(at: Vector2) -> void:
	for i in 10:
		var p := Polygon2D.new()
		var r := 3.0 + randf() * 4.0
		p.polygon = PackedVector2Array([Vector2(-r, -r), Vector2(r, -r), Vector2(r, r), Vector2(-r, r)])
		p.color = COLORS[_color_i % COLORS.size()]
		p.position = at + Vector2(randf_range(-20, 20), randf_range(-8, 8))
		world.add_child(p)
		var dir := Vector2(randf_range(-1, 1), randf_range(-1.2, -0.2)).normalized() * randf_range(40, 120)
		var tw := create_tween()
		tw.tween_property(p, "position", p.position + dir, 0.35)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.35)
		tw.tween_callback(p.queue_free)


func _game_over() -> void:
	_alive = false
	if not _moving.is_empty() and is_instance_valid(_moving.node):
		var n: Node2D = _moving.node
		var tw := create_tween()
		tw.tween_property(n, "position:y", n.position.y + 400.0, 0.45)
		tw.parallel().tween_property(n, "modulate:a", 0.0, 0.45)
	AudioBus.play_fail()
	SaveData.note_score(_score)
	_paint_hud()
	over.visible = true
	over.modulate.a = 0.0
	create_tween().tween_property(over, "modulate:a", 1.0, 0.35)
