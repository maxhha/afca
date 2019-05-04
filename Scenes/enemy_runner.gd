extends KinematicBody2D

const ATTACK_DISTANCE = 220
const MOVE_SPEED = 200

const ATTACK_TIMEOUT = 0.3

const DAMAGED_EFF_T = 0.2

enum STATES {STAND, RUN, ATTACK}

var STATE = STATES.STAND

var linear_vel = Vector2()
var _target 
var health = 2 setget set_health

var _damaged_timer = 0
var timer = 0

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
			
			var e = get_nearest_enemy()
			
			if e != null:
				if can_attack(e):
					start_attack(e)
				else:
					move_to(e)
		
		STATES.RUN:
			var e = get_nearest_enemy()
			if e:
				if can_attack(e):
					start_attack(e)
				else:
					_target = e
			
			if not is_instance_valid(_target):
				STATE = STATES.STAND
	
	#update
	match STATE:
		STATES.STAND:
			linear_vel = linear_vel.linear_interpolate(Vector2.ZERO, 0.4)
			
		STATES.RUN:
			
			linear_vel = linear_vel.linear_interpolate((_target.global_position - global_position).normalized()*MOVE_SPEED, 0.4)
		STATES.ATTACK:
			timer = max(0, timer - delta)
			if timer == 0:
				STATE = STATES.STAND
	#animation
	match STATE:
		STATES.RUN:
			rotation = linear_vel.angle()

func can_attack(e):
	if e.global_position.distance_to(global_position) > ATTACK_DISTANCE:
		return false
	$ray_walls.cast_to = e.global_position - global_position
	$ray_walls.rotation = -rotation
	$ray_walls.force_raycast_update()
	return not $ray_walls.is_colliding()

func get_nearest_enemy():
	var enemies = $view_area.get_overlapping_bodies()
	if enemies.size() == 0:
		return null
	
	var d_min
	var e_min
	
	for e in enemies:
		if e.is_queued_for_deletion():
			continue
		var d = e.global_position.distance_to(global_position) 
		if e_min == null or d_min > d:
			d_min = d
			e_min = e
	
	return e_min

var Bullet = preload("res://Scenes/bullet.tscn")

func start_attack(e):
	_target = e
	linear_vel = Vector2()
	STATE = STATES.ATTACK
	timer = ATTACK_TIMEOUT
	rotation = (e.global_position - global_position).angle()
	
	var b = Bullet.instance().init(e.global_position - global_position)
	get_parent().add_child(b)
	b.global_position = global_position + Vector2(1,0).rotated(rotation)*20
	$shoot1.play()

func move_to(e):
	_target = e
	STATE = STATES.RUN

func _process(delta):
	_damaged_timer = max(_damaged_timer - delta, 0)
	var k = ease(_damaged_timer / DAMAGED_EFF_T, 0.5)
	$sprite_white.modulate.a = k
#
#func _draw():
#	draw_circle(Vector2(), ATTACK_DISTANCE, Color("40f00000"))

func get_damage(dmg):
	self.health -= dmg