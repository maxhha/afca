tool
extends Node2D
export (float) var radius = 10 setget set_radius
export (int) var draw_points = 25 setget set_draw_points

func _ready():
	if not (Engine.is_editor_hint() or (global and global.SHOW_HINTS)):
		queue_free()

func set_radius(r):
	radius = r
	update()

func set_draw_points(p):
	draw_points = p
	update()

func _draw():
	for i in range(draw_points):
		draw_line(Vector2(radius, 0).rotated(i*TAU/draw_points), Vector2(radius, 0).rotated((i+1)*TAU/draw_points),modulate)