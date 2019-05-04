extends Node2D

onready var units = get_node('../units');

var offset = Vector2();
var direction = -1

func _ready():
	offset.y = get_viewport_rect().size.y/4

# warning-ignore:unused_argument
func _process(delta):
	if units.get_child_count() > 0:
		var target = Vector2()
		
		for u in global.player_units:
			target += u.global_position
		var p = (target / global.player_units.size() + offset*direction)
		var y = p.y
		if direction >= 0:
			global_position.y = max(y, global_position.y)
		else:
			global_position.y = min(y, global_position.y)
		global_position.x = p.x