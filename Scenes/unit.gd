extends KinematicBody2D

const SHOOT_RAND = PI/12
const RUN_DISTANCE = 450
const ATTACK_DISTANCE = 325
const MOVE_SPEED = 400
const MIN_SPEED = 0.4
const ATTACK_TIMEOUT = 0.5
const STAND_TIME = 2
const STANDUP_TIMER = 0.3
const ROTATE_SPEED = PI / 0.3

const HIDING_TIME = 2

enum STATES{STAND, MOVE, AIM, ATTACK, HIDE, HIDING, STANDUP, DEATH}
var STATE = STATES.STAND

var linear_vel = Vector2()

var _owned_hide_point setget set_owned_hide_point

func set_owned_hide_point(p):
	if _owned_hide_point:
		_owned_hide_point.own()
	_owned_hide_point = p
	if _owned_hide_point:
		_owned_hide_point.own(self)

signal dead

var health = 5 setget set_health

func set_health(h):
	health = h
	if h <= 0:
		self._owned_hide_point = null
		STATE = STATES.DEATH
		emit_signal("dead")
		queue_free()

var _target
var _target_pos
var _target_rot
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
			
			timer -= delta
			
			if e:
				if can_attack(e):
					start_attack(e)
				elif _owned_hide_point and timer <= 0:
					hide_at(_owned_hide_point)
				else:
					rotation = (e.global_position - global_position).angle()
			else:
				if _owned_hide_point and timer <= 0:
					hide_at(_owned_hide_point)
		STATES.HIDE:
			if _target_pos.distance_to(global_position) <= MOVE_SPEED*delta:
				if rotation == _owned_hide_point.get_rotation():
					start_hiding()
		
		STATES.HIDING:
			timer -= delta
			if timer <= 0:
				start_standup(_owned_hide_point.get_stand_rotation())
				
		
		STATES.STANDUP:
			timer -= delta
			if timer <= 0 and cos(rotation - _target_rot) > 0.99:
				STATE = STATES.STAND
				timer = STAND_TIME
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
		
		STATES.HIDE:
			if _target_pos.distance_to(global_position) > MOVE_SPEED*delta:
				linear_vel = linear_vel.linear_interpolate((_target_pos - global_position).normalized()*MOVE_SPEED, 0.4)
			else:
				global_position = _target_pos
				linear_vel = Vector2()
				rotate_to(_owned_hide_point.get_rotation(), ROTATE_SPEED*delta)
		STATES.STANDUP:
			rotate_to(_target_rot, ROTATE_SPEED*delta)
	
	#animation
	match STATE:
		STATES.STAND:
			$sprite.play('stand')
			
		STATES.MOVE:
			var e = get_nearest_enemy()
			if e:
				_targeting = true
				rotation = (e.global_position - global_position).angle()
			elif linear_vel.length() >= MIN_SPEED:
				rotation = linear_vel.angle()
				_targeting = false
			$sprite.play('run')
		STATES.STANDUP:
			$sprite.play('stand_up')
		
		STATES.HIDE:
			if linear_vel.length_squared() > 0:
				rotation = linear_vel.angle()
			else:
				$sprite.play('stand_down')
		STATES.HIDING:
			$sprite.play('hiding')
	
	if _shoot_timer > 0:
		_shoot_timer -= delta
		if _shoot_timer <= 0:
			var b = Bullet.instance().init(Vector2(1,0).rotated(rotation + (randf()-0.5)*SHOOT_RAND), true)
			for i in _ignore:
				b.add_collision_exception_with(i)
			
			get_parent().add_child(b)
			b.global_position = global_position + Vector2(1,0).rotated(rotation)*80

func rotate_to(r, step):
	r = deg2rad(rad2deg(r))
	var c = acos(cos(r - rotation))
	
	if c < step:
		rotation = r 
	else:
		var d = sign(sin(r - rotation))
		if d == 0:
			d = randi() % 2 * 2 - 1
		rotation += d * step

func move_to(point):
	_target = point
	self._owned_hide_point = null
	STATE = STATES.MOVE

func look(point):
	if STATE == STATES.STAND:
		var r = (point - global_position).angle()
		if _targeting:
			rotation -= sin(rotation - r)*0.5
		else:
			rotation = r

func can_move():
	return STATE == STATES.STAND or STATE == STATES.HIDING or STATE == STATES.ATTACK

func is_hiding():
	return STATE == STATES.HIDING

func start_hiding():
	STATE = STATES.HIDING
	global_position = _target_pos
	rotation = _owned_hide_point.get_rotation()
	timer = HIDING_TIME
	_target = null
	linear_vel = Vector2()

func get_nearest_enemy():
	var enemies = $view_area.get_overlapping_bodies()
	if enemies.size() == 0:
		return null
	
	var d_min
	var e_min
	var a = false
	
	for e in enemies:
		if e.is_queued_for_deletion():
			continue
		var d = e.global_position.distance_to(global_position) 
		if e_min == null or (can_attack(e) and not a) or (can_attack(e) == a and d_min > d):
			d_min = d
			e_min = e
			a = can_attack(e)
	
	return e_min

func can_attack(e):
	if e.global_position.distance_to(global_position) > ATTACK_DISTANCE:
		return false
	$ray_walls.cast_to = e.global_position - global_position
	$ray_walls.rotation = -rotation
	
	$ray_walls.clear_exceptions()
	
	for i in _ignore:
		$ray_walls.add_exception(i)
	
	while true:
		$ray_walls.force_raycast_update()
		if not $ray_walls.is_colliding():
			return true
		if $ray_walls.get_collider().is_in_group('obstacle'):
			for i in $ray_walls.get_collider().get_ignore_objects():
				if i == e:
					return false
				else:
					$ray_walls.add_exception(i)
			$ray_walls.add_exception($ray_walls.get_collider())
			continue
		return false

var Bullet = preload("res://Scenes/bullet.tscn")

func start_attack(e):
	_target = e
	linear_vel = Vector2()
	STATE = STATES.ATTACK
	timer = ATTACK_TIMEOUT
	rotation = (e.global_position - global_position).angle()
	shoot()

func get_damage(dmg):
	self.health -= dmg
	if STATE == STATES.HIDING:
		start_standup()
		self._owned_hide_point = null
	elif STATE != STATES.DEATH and _owned_hide_point:
		hide_at(_owned_hide_point)

func start_standup(target_rot=rotation):
	STATE = STATES.STANDUP
	timer = STANDUP_TIMER
	_target_rot = target_rot

func is_free_move_to(p):
	return global_position.distance_to(p) <= RUN_DISTANCE and not test_move(transform, p - global_position, false)

var _ignore = []

func add_ignore(obj):
	_ignore.append(obj)
	add_collision_exception_with(obj)

func remove_ignore(obj):
	_ignore.erase(obj)
	remove_collision_exception_with(obj)

const CREATE_BULLET_TIMEOUT = 0.08
var _shoot_timer = 0

func shoot():
	$shoot1.play()
	_shoot_timer = CREATE_BULLET_TIMEOUT

const OFFSET_SIZE = 20

func hide_at(p):
	self._owned_hide_point = p
	_target_pos = p.to_global(OFFSET_SIZE)
	STATE = STATES.HIDE

func get_hide_point():
	return _owned_hide_point

