tool
extends Node2D
export (float) var radius = 10 setget set_radius
export (int) var draw_points = 25 setget set_draw_points
export (bool) var fill = false setget set_fill
export (bool) var always_show = false 

func _ready():
	if not (Engine.is_editor_hint() or (global and global.SHOW_HINTS) or always_show):
		queue_free()

func set_radius(r):
	radius = r
	update()

func set_draw_points(p):
	draw_points = p
	update()

func set_fill(f):
	fill = f
	update()

func _draw():
	if fill:
		draw_circle(Vector2(0,0), radius, modulate)
	else:
		for i in range(draw_points):
			draw_line(Vector2(radius, 0).rotated(i*TAU/draw_points), Vector2(radius, 0).rotated((i+1)*TAU/draw_points),modulate)