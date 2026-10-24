extends Node2D
## Soft brand halo for the menu hero.


func _draw() -> void:
	draw_arc(Vector2.ZERO, 78.0, 0.0, TAU, 72, Color(0.94, 0.84, 0.62, 0.55), 4.0, true)
	draw_arc(Vector2.ZERO, 42.0, 0.0, TAU, 56, Color(0.94, 0.84, 0.62, 0.22), 2.0, true)
	draw_circle(Vector2.ZERO, 12.0, Color(0.94, 0.84, 0.62, 0.85))
