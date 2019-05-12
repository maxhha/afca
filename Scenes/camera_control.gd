extends Node2D

var offset = Vector2();
var direction = -1

func _ready():
	offset.y = 256

const CAMERA_SHAKE_T = 0.2
var _camera_shake_pwr = 0
var _camera_shake_timer = 0

func shake(pwr):
	_camera_shake_timer = CAMERA_SHAKE_T
	_camera_shake_pwr = pwr

# warning-ignore:unused_argument
func _process(delta):
	_camera_shake_timer = max(0, _camera_shake_timer - delta)
	
	$camera.offset = Vector2(_camera_shake_pwr*32*_camera_shake_timer/CAMERA_SHAKE_T,0).rotated(randf()*TAU) 
	
	
	if global.player:
		
		var target = global.player.global_position
		var p = (target + get_global_mouse_position()) / 2
		var y = p.y
		var t = Vector2(p.x,p.y)
#		if direction >= 0:
#			t.y = max(y, global_position.y)
#		else:
#			t.y = min(y, global_position.y)
		
		t.y = min(t.y, 0)
		global_position = global_position.linear_interpolate(t, 0.2)