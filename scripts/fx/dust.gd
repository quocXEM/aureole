extends Node2D

var _bits: Array = []


func _ready() -> void:
	for i in 28:
		_bits.append({
			"p": Vector2(randf() * 720.0, randf() * 2000.0 - 400.0),
			"r": randf_range(1.2, 2.8),
			"a": randf_range(0.04, 0.14),
			"s": randf_range(8.0, 22.0),
			"ph": randf() * TAU,
		})


func _process(delta: float) -> void:
	for b in _bits:
		b.ph += delta * 0.6
		b.p.y -= b.s * delta * 0.15
		b.p.x += sin(b.ph) * 6.0 * delta
		if b.p.y < -500.0:
			b.p.y = 1600.0
			b.p.x = randf() * 720.0
	queue_redraw()


func _draw() -> void:
	for b in _bits:
		draw_circle(b.p, b.r, Color(0.95, 0.9, 0.8, b.a))
