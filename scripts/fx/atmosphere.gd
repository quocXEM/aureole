extends Node2D
## Soft vertical wash + floating dust — art-casual atmosphere.


func _ready() -> void:
	z_index = -6
	queue_redraw()
	var dust := Node2D.new()
	dust.set_script(preload("res://scripts/fx/dust.gd"))
	dust.z_index = -5
	add_child(dust)


func _draw() -> void:
	var w := 1080.0
	var h := 10000.0
	var top := Color(0.11, 0.09, 0.12, 1)
	var mid := Color(0.07, 0.06, 0.08, 1)
	var bot := Color(0.05, 0.045, 0.055, 1)
	var steps := 24
	for i in steps:
		var t0 := float(i) / float(steps)
		var t1 := float(i + 1) / float(steps)
		var c0 := top.lerp(mid, clampf(t0 * 1.4, 0.0, 1.0)).lerp(bot, clampf((t0 - 0.45) * 1.6, 0.0, 1.0))
		draw_rect(Rect2(0.0, t0 * h - 3000.0, w, (t1 - t0) * h + 2.0), c0)
