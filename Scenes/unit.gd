extends KinematicBody2D

const SHOOT_RAND = PI/12
const RUN_DISTANCE = 450
const ATTACK_DISTANCE = 450
export (float) var MOVE_SPEED = 500
const MIN_SPEED = 0.4
export (float) var ATTACK_TIMEOUT = 0.5
const STAND_TIME = 2
const STANDUP_TIMER = 0.3
const ROTATE_SPEED = PI / 0.3
export (int) var MAX_HEALTH = 3
const SLIDE_ACCUM_PWR = 100

const START_FOLLOW_DISTANCE = 400

const HIDING_TIME_MIN = 1
const HIDING_TIME_MAX = 2

enum STATES{STAND, MOVE, AIM, ATTACK, HIDE, HIDING, STANDUP, TARGETTING, DEATH, FOLLOW}
var STATE = STATES.STAND

var linear_vel = Vector2()

var _owned_ship_point 
var _owned_hide_point setget set_owned_hide_point

func set_owned_hide_point(p):
	if _owned_hide_point:
		_owned_hide_point.own()
	_owned_hide_point = p
	if _owned_hide_point:
		_owned_hide_point.own(self)

signal dead

var health = 7 setget set_health

func set_health(h):
	health = h
	if h <= 0:
		self._owned_hide_point = null
		if _owned_ship_point:
			_owned_ship_point.own()
		STATE = STATES.DEATH
		emit_signal("dead")
		queue_free()

var _target
var _target_pos
var _target_rot
var _next 
var _targeting = false
var _is_hiding = false

var timer = 0

func _ready():
	health = MAX_HEALTH
	$sprite.material = $sprite.material.duplicate()
	rotation = PI / 4 * ( - 3 + randf() * 2)

func _physics_process(delta):
	
	linear_vel = move_and_slide(linear_vel)
	
	#update
	match STATE:
		STATES.STAND:
			if not should_follow():
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
				if cos(rotation - _owned_hide_point.get_rotation()) > 0.99:
					start_hiding()
		
		STATES.HIDING:
			if not should_follow():
				timer -= delta
				if timer <= 0:
					start_standup(_owned_hide_point.get_stand_rotation())
		
		STATES.STANDUP:
			timer -= delta
			if timer <= 0 and cos(rotation - _target_rot) > 0.99:
				
				if _next == null:
					STATE = STATES.STAND
					timer = STAND_TIME
				else:
					callv(_next['t'],_next['a'])
		
		STATES.TARGETTING:
			if not is_instance_valid(_target):
				if _owned_hide_point:
					hide_at(_owned_hide_point)
				else:
					STATE = STATES.STAND
			elif can_attack(_target):
				start_attack(_target, {'t':"attack_to", "a": [_target]})
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
				if _next:
					callv(_next['t'], _next['a'])
				else:
					STATE = STATES.STAND
		
		STATES.HIDE:
			if _target_pos.distance_to(global_position) > MOVE_SPEED*delta:
				linear_vel = linear_vel.linear_interpolate((_target_pos - global_position).normalized()*MOVE_SPEED, 0.4)
			else:
				global_position = _target_pos
				linear_vel = Vector2()
				rotation = rotate_to(rotation,_owned_hide_point.get_rotation(), ROTATE_SPEED*delta)
		STATES.STANDUP:
			rotation = rotate_to(rotation,_target_rot, ROTATE_SPEED*delta)
		STATES.TARGETTING:
			if is_instance_valid(_target):
				rotation = rotate_to(rotation,(_target.global_position - global_position).angle(),ROTATE_SPEED*delta)
	
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
		
		STATES.FOLLOW:
			if linear_vel.length() > MIN_SPEED:
				var e = get_nearest_enemy()
				if e:
					_targeting = true
					rotation = (e.global_position - global_position).angle()
				elif linear_vel.length() >= MIN_SPEED:
					rotation = linear_vel.angle()
					_targeting = false
				$sprite.play('run')
			else:
				$sprite.play('stand')
		
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
			b.global_position = $shoot_point.global_position

const FOLLOW_DISTANCE = 100
const FOLLOW_DISTANCE_HIDING_Y = 200

func should_follow():
	if _owned_ship_point and global.player:
		var p = _owned_ship_point.to_global()
		if (not _is_hiding and p.distance_to(global_position) > FOLLOW_DISTANCE) or global_position.y - global.player.global_position.y > FOLLOW_DISTANCE_HIDING_Y:
			move_to(p+global.player.linear_vel * FOLLOW_DISTANCE*2 / MOVE_SPEED)
			
			return true
		if _owned_hide_point != null and _owned_hide_point.parent.is_owned_by_enemy():
			
			move_to(p+global.player.linear_vel * FOLLOW_DISTANCE*2 / MOVE_SPEED)
			return true
	
	elif global.player:
		if global.player.global_position.distance_to(global_position) <= START_FOLLOW_DISTANCE:
			_owned_ship_point = global.player.get_nearest_point_to(global_position)
			
			if _owned_ship_point:
				_owned_ship_point.own(self)
	
	return false

func start_follow():
	STATE = STATES.FOLLOW

const DAMAGED_EFF_T = 0.2
var _damaged_timer = 0

func _process(delta):
	_damaged_timer = max(_damaged_timer - delta, 0)
	var k = ease(_damaged_timer / DAMAGED_EFF_T, 0.5)
	$sprite.get_material().set_shader_param('k', k)

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

func move_to(point):
	_target = point
	self._owned_hide_point = null
	_is_hiding = false
	STATE = STATES.MOVE

func look(point):
	if STATE == STATES.STAND:
		var r = (point - global_position).angle()
		if _targeting:
			rotation -= sin(rotation - r)*0.5
		else:
			rotation = r

func can_move():
	return STATE == STATES.STAND or STATE == STATES.HIDING or STATE == STATES.ATTACK or STATE == STATES.TARGETTING

func attack_to(obj):
	if not is_instance_valid(obj):
		start_targetting(obj)
	elif STATE == STATES.HIDING:
		start_standup(_owned_hide_point.get_stand_rotation(), {'t':'start_targetting', 'a':[obj]})
	else:
		start_targetting(obj)

func start_targetting(obj):
	_target = obj
	STATE = STATES.TARGETTING 

func is_hiding():
	return STATE == STATES.HIDING or STATE == STATES.STANDUP

func start_hiding():
	STATE = STATES.HIDING
	global_position = _target_pos
	rotation = _owned_hide_point.get_rotation()
	timer = lerp(HIDING_TIME_MIN, HIDING_TIME_MAX,randf())
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

func can_target(e):
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
			$ray_walls.add_exception($ray_walls.get_collider())
			continue
		return false

func check_wall_ray(pos):
	var r = pos - global_position
	r = r.normalized()*(r.length() + OFFSET_SIZE)
	$ray_walls.cast_to = r

	$ray_walls.global_rotation = 0
	
	$ray_walls.clear_exceptions()
	$ray_walls.force_raycast_update()
	return $ray_walls.is_colliding()

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

func start_attack(e, next=null):
	_target = e
	linear_vel = Vector2()
	STATE = STATES.ATTACK
	timer = ATTACK_TIMEOUT
	rotation = (e.global_position - global_position).angle()
	_next = next
	shoot()

func get_damage(dmg):
	self.health -= dmg
	if STATE == STATES.HIDING:
		start_standup()
		self._owned_hide_point = null
	elif STATE != STATES.DEATH and _owned_hide_point:
		hide_at(_owned_hide_point)
	_damaged_timer = DAMAGED_EFF_T

func start_standup(target_rot=rotation, next=null):
	STATE = STATES.STANDUP
	timer = STANDUP_TIMER
	_target_rot = target_rot
	_next = next

func is_free_move_to(p):
	return not test_move(transform, p - global_position, false)

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
	_is_hiding = true
	self._owned_hide_point = p
	_target_pos = p.to_global(OFFSET_SIZE)
	STATE = STATES.HIDE

func get_hide_point():
	return _owned_hide_point

