extends Node2D
## Soft brand halo for the menu hero.


func _draw() -> void:
	draw_arc(Vector2.ZERO, 52.0, 0.0, TAU, 64, Color(0.94, 0.84, 0.62, 0.55), 3.0, true)
	draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 48, Color(0.94, 0.84, 0.62, 0.22), 1.5, true)
	draw_circle(Vector2.ZERO, 8.0, Color(0.94, 0.84, 0.62, 0.85))
