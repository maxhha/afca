extends KinematicBody2D

const MOVE_SPEED = 400
const MIN_SPEED = 0.4

enum STATES{STAND, MOVE}
var STATE = STATES.STAND

var linear_vel = Vector2()

var _target = Vector2()

func _ready():
	rotation = PI / 4 * ( - 3 + randf() * 2)

func _physics_process(delta):
	
	linear_vel = move_and_slide(linear_vel)
	
	match STATE:
		STATES.STAND:
			linear_vel = linear_vel.linear_interpolate(Vector2.ZERO, 0.4)
		STATES.MOVE:
			var d = _target - global_position
			if d.length() <= MOVE_SPEED*delta:
				STATE = STATES.STAND
			else:
				linear_vel = d.normalized() * MOVE_SPEED
	
	if linear_vel.length() >= MIN_SPEED:
		rotation = linear_vel.angle()

func move_to(point):
	_target = point
	STATE = STATES.MOVE

func can_move():
	return STATE == STATES.STAND
	
func is_free_move_to(p):
	return not test_move(transform, p - global_position)