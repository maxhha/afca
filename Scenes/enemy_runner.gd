extends KinematicBody2D

const SHOOT_RAND = PI/12
export (float) var ATTACK_DISTANCE = 450
export (float) var MOVE_SPEED = 400
const HIDE_TIME = 0.2
const HIDING_TIME_MIN = 1
const HIDING_TIME_MAX = 1.5
const STAND_TIME = 2
const STANDUP_TIMER = 0.3
const ROTATE_SPEED = PI / 0.3

export (float) var ATTACK_TIMEOUT = 0.5

const DAMAGED_EFF_T = 0.2

enum STATES {STAND, MOVE, ATTACK, HIDE, HIDING, STANDUP, DEATH}

var STATE = STATES.STAND

var linear_vel = Vector2()

var _target 
var _target_pos
var _target_rot

export (int) var MAX_HEALTH = 3
var health = 3 setget set_health

var _damaged_timer = 0
var timer = 0

func _ready():
	z_index = 3
	health = MAX_HEALTH
	$sprite.material = $sprite.material.duplicate()

func set_health(h):
	health = h
	_damaged_timer = DAMAGED_EFF_T
	if h <= 0:
		self._owned_hide_point = null
		STATE = STATES.DEATH
		queue_free()

func _physics_process(delta):
	linear_vel = move_and_slide(linear_vel)
	#logic
	match STATE:
		STATES.STAND:
			timer = max(timer - delta, 0)
			var e = get_nearest_enemy()
			
			if e != null:
				if can_attack(e):
					start_attack(e)
				else:
					var p = get_hide_point()
					if p == null:
						move_to(e)
					elif timer == 0:
						hide_at(p)
			
		STATES.MOVE:
			var e = get_nearest_enemy()
			if e:
				if can_attack(e):
					start_attack(e)
				else:
					var p = get_hide_point()
					if p == null:
						move_to(e)
					else:
						hide_at(p)
			
			if not is_instance_valid(_target):
				STATE = STATES.STAND
		
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
	

	#update
	match STATE:
		STATES.STAND:
			linear_vel = linear_vel.linear_interpolate(Vector2.ZERO, 0.4)
			
		STATES.MOVE:
			linear_vel = linear_vel.linear_interpolate((_target.global_position - global_position).normalized()*MOVE_SPEED, 0.4)
		STATES.HIDE:
			if _target_pos.distance_to(global_position) > MOVE_SPEED*delta:
				linear_vel = linear_vel.linear_interpolate((_target_pos - global_position).normalized()*MOVE_SPEED, 0.4)
			else:
				global_position = _target_pos
				linear_vel = Vector2()
				rotate_to(_owned_hide_point.get_rotation(), ROTATE_SPEED*delta)
				
		STATES.ATTACK:
			var e = get_nearest_enemy()
			if e:
				rotate_to((e.global_position - global_position).angle(), ROTATE_SPEED*delta)
			timer = max(0, timer - delta)
			if timer == 0:
				STATE = STATES.STAND
		
		STATES.STANDUP:
			rotate_to(_target_rot, ROTATE_SPEED*delta)
		
	#animation
	match STATE:
		STATES.STAND, STATES.ATTACK:
			$sprite.play('stand')

		STATES.MOVE:
			rotation = linear_vel.angle()
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
			var b = Bullet.instance().init(Vector2(1,0).rotated(rotation + (randf()-0.5)*SHOOT_RAND))
			for i in _ignore:
				b.add_collision_exception_with(i)
			
			get_parent().add_child(b)
			b.global_position = $shoot_point.global_position

func start_standup(target_rot=rotation):
	STATE = STATES.STANDUP
	timer = STANDUP_TIMER
	_target_rot = target_rot

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

func start_hiding():
	STATE = STATES.HIDING
	global_position = _target_pos
	rotation = _owned_hide_point.get_rotation()
	timer = lerp(HIDING_TIME_MIN, HIDING_TIME_MAX, randf())
	_target = null
	linear_vel = Vector2()

var _owned_hide_point setget set_owned_hide_point

func set_owned_hide_point(p):
	if _owned_hide_point:
		_owned_hide_point.own()
	_owned_hide_point = p
	if _owned_hide_point:
		_owned_hide_point.own(self)

func hide_at(p):
	self._owned_hide_point = p
	_target_pos = p.to_global(OFFSET_SIZE)
	STATE = STATES.HIDE

const OFFSET_SIZE = 20

func get_hide_point():
	var hide_areas = $hide_area.get_overlapping_areas()
	if hide_areas.size() == 0:
		return null
	if _owned_hide_point != null:
		return _owned_hide_point
	var min_d
	var min_p
	
	for h in hide_areas:
		var p = h.get_nearest_free_point_to(global_position)
		if p:
			var d = global_position.distance_to(p.to_global(OFFSET_SIZE))
			if min_d == null or (min_d > d):
				min_d = d
				min_p = p
	
	return min_p

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

func get_nearest_enemy():
	var enemies = $view_area.get_overlapping_bodies()
	if enemies.size() == 0:
		return null
	
	var d_min
	var e_min
	var c 
	
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d = e.global_position.distance_to(global_position) 
		var cc = can_attack(e)
		if e_min == null or ((cc == c and d_min > d) or (not c and cc)):
			d_min = d
			e_min = e
			c = cc
	
	return e_min

var Bullet = preload("res://Scenes/bullet.tscn")

func start_attack(e):
	_target = e
	linear_vel = Vector2()
	STATE = STATES.ATTACK
	timer = ATTACK_TIMEOUT
	rotation = (e.global_position - global_position).angle()
	shoot()


const CREATE_BULLET_TIMEOUT = 0.08#sec
var _shoot_timer = 0

func shoot():
	$shoot1.play()
	_shoot_timer = CREATE_BULLET_TIMEOUT

func move_to(e):
	self._target = e
	STATE = STATES.MOVE

func _process(delta):
	_damaged_timer = max(_damaged_timer - delta, 0)
	var k = ease(_damaged_timer / DAMAGED_EFF_T, 0.5)
	$sprite.get_material().set_shader_param('k', k)

func _draw():
	if global.SHOW_HINTS:
		draw_circle(Vector2(), ATTACK_DISTANCE, Color("40f00000"))

func get_damage(dmg):
	self.health -= dmg
	if STATE == STATES.HIDING:
		start_standup()
		self._owned_hide_point = null
	elif STATE != STATES.DEATH and _owned_hide_point:
		hide_at(_owned_hide_point)
	_damaged_timer = DAMAGED_EFF_T

func is_hiding():
	return STATE == STATES.HIDING

var _ignore = []

func add_ignore(obj):
	_ignore.append(obj)
	add_collision_exception_with(obj)

func remove_ignore(obj):
	_ignore.erase(obj)
	remove_collision_exception_with(obj)
