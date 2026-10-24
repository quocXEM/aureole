extends Control

@onready var title: Label = %Title
@onready var tag: Label = %Tag
@onready var best: Label = %Best
@onready var play_btn: Button = %PlayBtn
@onready var leave_btn: Button = %LeaveBtn
@onready var lang_btn: Button = %LangBtn
@onready var ring: Node2D = %BrandRing

var _t := 0.0


func _ready() -> void:
	play_btn.pressed.connect(_play)
	leave_btn.pressed.connect(func() -> void: get_tree().quit())
	lang_btn.pressed.connect(_toggle_lang)
	_refresh()
	Loc.language_changed.connect(func(_c): _refresh())
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5)
	# Soft dust
	var dust: Node2D = (load("res://scripts/fx/dust.gd") as GDScript).new()
	$Atmosphere.add_child(dust)


func _process(delta: float) -> void:
	_t += delta
	if ring:
		ring.rotation = _t * 0.15
		ring.scale = Vector2.ONE * (1.0 + 0.02 * sin(_t * 1.4))


func _refresh() -> void:
	title.text = Loc.tr_key("game.title")
	tag.text = Loc.tr_key("game.tag")
	best.text = Loc.tr_key("menu.best") % SaveData.best
	play_btn.text = Loc.tr_key("menu.play")
	leave_btn.text = Loc.tr_key("menu.leave")
	lang_btn.text = Loc.code.to_upper()


func _play() -> void:
	AudioBus.play_ui()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _toggle_lang() -> void:
	AudioBus.play_ui()
	Loc.set_language("vi" if Loc.code == "en" else "en")
