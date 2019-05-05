extends KinematicBody2D

const ATTACK_DISTANCE = 300
const MOVE_SPEED = 200
const HIDE_TIME = 0.2
const HIDING_TIME = 2
const STAND_TIME = 2

const ATTACK_TIMEOUT = 0.3

const DAMAGED_EFF_T = 0.2

enum STATES {STAND, MOVE, ATTACK, HIDE, HIDING, RISING, CHECKOUT}

var STATE = STATES.STAND

var linear_vel = Vector2()

var _target 
var _target_pos


var health = 2 setget set_health

var _damaged_timer = 0
var timer = 0

func set_health(h):
	health = h
	_damaged_timer = DAMAGED_EFF_T
	if h <= 0:
		self._owned_hide_point = null
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
				start_hiding()
		
		STATES.HIDING:
			timer -= delta
			if timer <= 0:
				STATE = STATES.STAND
				timer = STAND_TIME
				rotate(PI)
	
	#update
	match STATE:
		STATES.STAND:
			linear_vel = linear_vel.linear_interpolate(Vector2.ZERO, 0.4)
			
		STATES.MOVE:
			linear_vel = linear_vel.linear_interpolate((_target.global_position - global_position).normalized()*MOVE_SPEED, 0.4)
		STATES.HIDE:
			linear_vel = linear_vel.linear_interpolate((_target_pos - global_position).normalized()*MOVE_SPEED, 0.4)
		STATES.ATTACK:
			timer = max(0, timer - delta)
			if timer == 0:
				STATE = STATES.STAND
	#animation
	match STATE:
		STATES.MOVE:
			rotation = linear_vel.angle()
		STATES.HIDE:
			if _target_pos.distance_to(global_position) < MOVE_SPEED*HIDE_TIME:
				var r = _owned_hide_point.normal.angle()
				rotation += asin(sin(r-rotation)) / HIDE_TIME
			else:
				rotation = linear_vel.angle()


func start_hiding():
	STATE = STATES.HIDING
	global_position = _target_pos
	rotation = _owned_hide_point.normal.angle()
	timer = HIDING_TIME
	linear_vel = Vector2()

var _owned_hide_point setget set_owned_hide_point

func set_owned_hide_point(p):
	if _owned_hide_point:
		_owned_hide_point.own()
	_owned_hide_point = p
	if _owned_hide_point:
		_owned_hide_point.own(self)

func hide_at(p):
	if _owned_hide_point == p:
		start_hiding()
	else:
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
	for i in _ignore:
		b.add_collision_exception_with(i)
	get_parent().add_child(b)
	b.global_position = global_position + Vector2(1,0).rotated(rotation)*80
	$shoot1.play()

func move_to(e):
	self._target = e
	STATE = STATES.MOVE

func _process(delta):
	_damaged_timer = max(_damaged_timer - delta, 0)
	var k = ease(_damaged_timer / DAMAGED_EFF_T, 0.5)
	$sprite_white.modulate.a = k

func _draw():
	draw_circle(Vector2(), ATTACK_DISTANCE, Color("40f00000"))

func get_damage(dmg):
	self.health -= dmg

func is_hiding():
	return STATE == STATES.HIDING

var _ignore = []

func add_ignore(obj):
	_ignore.append(obj)
	add_collision_exception_with(obj)

func remove_ignore(obj):
	_ignore.erase(obj)
	remove_collision_exception_with(obj)
