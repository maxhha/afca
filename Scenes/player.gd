extends KinematicBody2D

const SHOOT_RAND = PI/40
#const RUN_DISTANCE = 450
#const ATTACK_DISTANCE = 325
const MOVE_SPEED = 400
const MIN_SPEED = 0.4
const ATTACK_TIMEOUT = 1.0/6
#const STAND_TIME = 2
#const STANDUP_TIMER = 0.3
const BODY_ROTATE_SPEED = PI/4*2
const ROTATE_SPEED = PI / 0.3

const MAX_HEALTH = 25

enum STATES {MOVE}
var STATE = STATES.MOVE

onready var gun = $sprite/gun
onready var shoot_points = $sprite/gun/shoot_points.get_children()
var current_sh_p = 0

var linear_vel = Vector2()

var _attack_timer = 0

class UnitPoint:
	var owned_by
	var pos
	var parent
	func _init(parent, pos):
		self.parent = parent
		self.pos = pos
	
	func to_global():
		return parent.to_global(pos)
	
	func own(o=null):
		owned_by = o 

var units_points = []

func _ready():
	for i in $units_poses.get_children():
		units_points.append(UnitPoint.new(self, i.position))
	$units_poses.free()
	$ui/health.max_value = MAX_HEALTH

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

const HIDE_AREA_TIMEOUT = 1
var _place_hide_area_timer = 1
var _damaged_timer = 0

func _process(delta):
	_damaged_timer = max(_damaged_timer - delta, 0)
	var k = ease(_damaged_timer / DAMAGED_EFF_T, 0.5)
	$sprite.get_material().set_shader_param('k', k)
	
	_place_hide_area_timer += delta
	if _place_hide_area_timer > HIDE_AREA_TIMEOUT:
		_place_hide_area_timer = 0
		for p in units_points:
			if p.owned_by == null:
				continue
			var u = p.owned_by
			p.owned_by = null
			
			if not is_instance_valid(u):
				continue
			
			for j in units_points:
				if j.owned_by == null:
					u._owned_ship_point = j
					j.own(u)
					break
			
			if u._owned_hide_point:
				continue
			for a in $hide_area.get_overlapping_areas():
				if a.global_position.y >= global_position.y + 100 or a.is_owned_by_enemy():
					continue
				
				if a.global_position.y < global_position.y + 100:
					var h = a.get_nearest_free_point_to(u.global_position, global_position)
					if h:
						u.hide_at(h)
		
		
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
	var anim = $sprite/gun/sprite/anim

	anim.play('shoot', -1, 0.2/ATTACK_TIMEOUT)

func get_nearest_point_to(pos):
	var d_min
	var p_min
	var i = 0
	for p in units_points:
		var d = p.to_global().distance_to(pos) - i*64
		if p.owned_by == null and (d_min == null or d_min > d):
			d_min = d
			p_min = p
		i += 1
	return p_min

var health = MAX_HEALTH setget set_health
signal dead
func set_health(s):
	health = s
	$ui/health.value = health
	if s <= 0:
		var b = preload("res://Scenes/rocket_destroy.tscn").instance()
		get_parent().add_child(b)
		b.global_position = global_position
		emit_signal('dead')
		queue_free()

const DAMAGED_EFF_T = 0.2

func get_damage(dmg):
	self.health -= dmg
	global.camera_shake(0.5 if dmg < 2 else 1.0)
	_damaged_timer = DAMAGED_EFF_T