extends KinematicBody2D

const ATTACK_DISTANCE = 300
const MOVE_SPEED = 400
const MIN_SPEED = 0.4
const ATTACK_TIMEOUT = 0.25

enum STATES{STAND, MOVE, AIM, ATTACK}
var STATE = STATES.STAND

var linear_vel = Vector2()

signal dead

var health = 3 setget set_health

func set_health(h):
	health = h
	if h <= 0:
		emit_signal("dead")
		queue_free()

var _target
var _targeting = false

var timer = 0

#func _ready():
#	rotation = PI / 4 * ( - 3 + randf() * 2)

func _physics_process(delta):
	
	linear_vel = move_and_slide(linear_vel)
	
	#update
	match STATE:
		STATES.STAND:
			var e = get_nearest_enemy()
			
			if e:
				if can_attack(e):
					start_attack(e)
				else:
					rotation = (e.global_position - global_position).angle()
					
	#action
	match STATE:
		STATES.STAND:
			linear_vel = linear_vel.linear_interpolate(Vector2.ZERO, 0.4)
		STATES.MOVE:
			var d = _target - global_position
			if d.length() <= MOVE_SPEED*delta:
				STATE = STATES.STAND
			else:
				linear_vel = d.normalized() * MOVE_SPEED
		
		STATES.ATTACK:
			timer = max(timer - delta, 0)
			if timer == 0:
				STATE = STATES.STAND
	
	
	#animation
	match STATE:
		STATES.MOVE:
			var e = get_nearest_enemy()
			if e:
				_targeting = true
				rotation = (e.global_position - global_position).angle()
			elif linear_vel.length() >= MIN_SPEED:
				rotation = linear_vel.angle()
				_targeting = false

func move_to(point):
	_target = point
	STATE = STATES.MOVE

func look(point):
	var r = (point - global_position).angle()
	if _targeting:
		rotation -= sin(rotation - r)*0.5
	else:
		rotation = r

func can_move():
	return STATE == STATES.STAND

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

func can_attack(e):
	if e.global_position.distance_to(global_position) > ATTACK_DISTANCE:
		return false
	$ray_walls.cast_to = e.global_position - global_position
	$ray_walls.rotation = -rotation
	$ray_walls.force_raycast_update()
	return not $ray_walls.is_colliding()

var Bullet = preload("res://Scenes/bullet.tscn")

func start_attack(e):
	_target = e
	linear_vel = Vector2()
	STATE = STATES.ATTACK
	timer = ATTACK_TIMEOUT
	rotation = (e.global_position - global_position).angle()
	
	var b = Bullet.instance().init(e.global_position - global_position, true)
	get_parent().add_child(b)
	b.global_position = global_position + Vector2(1,0).rotated(rotation)*20
	$shoot1.play()

func get_damage(dmg):
	self.health -= dmg

func is_free_move_to(p):
	return not test_move(transform, p - global_position, false)