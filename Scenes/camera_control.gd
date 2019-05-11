extends Node2D

var offset = Vector2();
var direction = -1

func _ready():
	offset.y = 256

# warning-ignore:unused_argument
func _process(delta):
	if global.player_units.size() > 0:
		var target = Vector2()
		
		for u in global.player_units:
			target += u.global_position
		var p = (target / global.player_units.size()*2 + get_global_mouse_position()) / 3
		var y = p.y
		var t = Vector2(p.x,p.y)
#		if direction >= 0:
#			t.y = max(y, global_position.y)
#		else:
#			t.y = min(y, global_position.y)
		
		
		global_position = global_position.linear_interpolate(t, 0.2)