extends Node2D

onready var units = get_node('../units');

var offset = Vector2();

func _ready():
	offset.y = -get_viewport_rect().size.y/4

func _process(delta):
	if units.get_child_count() > 0:
		var target = Vector2()
		
		for u in units.get_children():
			target += u.global_position
		
		global_position.y = (target / units.get_child_count() + offset).y