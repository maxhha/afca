extends KinematicBody2D

const SHOOT_RAND = PI/16
#const RUN_DISTANCE = 450
#const ATTACK_DISTANCE = 325
const MOVE_SPEED = 200
const MIN_SPEED = 0.4
const ATTACK_TIMEOUT = 1.0/5
#const STAND_TIME = 2
#const STANDUP_TIMER = 0.3
const BODY_ROTATE_SPEED = PI/4
const ROTATE_SPEED = PI / 0.3

enum STATES {MOVE}
var STATE = STATES.MOVE

onready var gun = $sprite/gun
onready var shoot_points = $sprite/gun/shoot_points.get_children()
var current_sh_p = 0

var linear_vel = Vector2()

var _attack_timer = 0

func _physics_process(delta):
	linear_vel = move_and_slide(linear_vel)
	#action
	match STATE:
		STATES.MOVE:
			var d = 0
			if Input.is_action_pressed("left"):
				d -= 1
			if Input.is_action_pressed("right"):
				d += 1
			
			rotation += BODY_ROTATE_SPEED * delta * d
			
			d = 0
			if Input.is_action_pressed("up"):
				d += 1
			if Input.is_action_pressed("down"):
				d -= 1
			
			linear_vel = linear_vel.linear_interpolate(Vector2(d*MOVE_SPEED, 0).rotated(rotation), 0.2)
			
			var target = get_global_mouse_position() - gun.global_position
			gun.global_rotation = rotate_to(gun.global_rotation, target.angle(), ROTATE_SPEED*delta)
			
			if Input.is_action_pressed('click') and _attack_timer <= 0:
				shoot()
	
	_attack_timer -= delta

func rotate_to(rot, r, step):
	r = deg2rad(rad2deg(r))
	var c = acos(cos(r - rot))
	
	if c < step:
		rot = r 
	else:
		var d = sign(sin(r - rot))
		if d == 0:
			d = randi() % 2 * 2 - 1
		rot += d * step
	return rot

var Bullet = preload("res://Scenes/bullet.tscn")

func shoot():
	_attack_timer = ATTACK_TIMEOUT
	var b = Bullet.instance().init(Vector2(1,0).rotated(gun.global_rotation + (randf()-0.5)*SHOOT_RAND), true)
	b.z_index = 257
	get_parent().add_child(b)
	b.global_position = shoot_points[current_sh_p].global_position
	shoot_points[current_sh_p].get_node('snd').play()
	current_sh_p = (current_sh_p + 1) % shoot_points.size()
	$sprite/gun/sprite/anim.play('shoot')
	