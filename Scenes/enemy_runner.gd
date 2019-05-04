extends KinematicBody2D

const VIEW_DISTANCE = 450
const ATTACK_DISTANCE = 200
const MOVE_SPEED = 200

const DAMAGED_EFF_T = 0.2

enum STATES {STAND, RUN, ATTACK}

var STATE = STATES.STAND

var linear_vel = Vector2()
var _target 
var health = 2 setget set_health

var _damaged_timer = 0

func set_health(h):
	health = h
	_damaged_timer = DAMAGED_EFF_T
	if h <= 0:
		queue_free()

func _physics_process(delta):
	linear_vel = move_and_slide(linear_vel)
	#logic
	match STATE:
		STATES.STAND:
			for u in global.player_units:
				var d = u.global_position.distance_to(global_position)
				if d <= VIEW_DISTANCE and d > 100:
					_target = u
					STATE = STATES.RUN
					break
		
		STATES.RUN:
			if _target.global_position.distance_to(global_position) <= 100:
				STATE = STATES.STAND
	
	#update
	match STATE:
		STATES.STAND:
			linear_vel = linear_vel.linear_interpolate(Vector2.ZERO, 0.4)
			
		STATES.RUN:
			linear_vel = linear_vel.linear_interpolate((_target.global_position - global_position).normalized()*MOVE_SPEED, 0.4)
	
	#animation
	match STATE:
		STATES.RUN:
			rotation = linear_vel.angle()

func _process(delta):
	_damaged_timer = max(_damaged_timer - delta, 0)
	var k = ease(_damaged_timer / DAMAGED_EFF_T, 0.5)
	$sprite_white.modulate.a = k

#func _draw():
#	draw_circle(Vector2(), VIEW_DISTANCE, Color("40f0f0f0"))
#	draw_circle(Vector2(), ATTACK_DISTANCE, Color("40f00000"))

func get_damage(dmg):
	self.health -= dmg