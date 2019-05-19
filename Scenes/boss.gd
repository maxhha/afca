extends KinematicBody2D

const SHOOT_RAND = PI/3
const ATTACK_DISTANCE = 950
export (float) var ATTACK_TIMEOUT = 0.4

const ROTATION_SPEED = PI/4

const DAMAGED_EFF_T = 0.2

var health = 33 setget set_health
signal dead

func set_health(h):
	health = h
	if h <= 0:
		emit_signal("dead")
		var d = preload("res://Scenes/rocket_destroy.tscn").instance()
		get_parent().add_child(d)
		d.global_position = global_position
		d.z_index = z_index
		queue_free()

onready var gun = $gun
onready var count_guns = $gun/shoot_points.get_child_count()
var current_gun = 0

var shoot_timer = 0
var _damaged_timer = 0

var sprites = []

func _ready():
	for n in [$sprite, $gun/sprite, $gun/sprite/gun1, $gun/sprite/gun2]:
		n.material = n.material.duplicate()
		sprites.append(n)

func _physics_process(delta):
	if global.player:
		var d = global.player.global_position - global_position
		if d.length() <= ATTACK_DISTANCE:
			var r = d.angle()
			if cos(r - gun.global_rotation) > 0.99:
				if shoot_timer <= 0:
					shoot()
			else:
				gun.global_rotation = rotate_to(gun.global_rotation, r, delta * ROTATION_SPEED)
	
	shoot_timer -= delta
	
func _process(delta):
	_damaged_timer = max(0, _damaged_timer - delta)
	var k = ease(_damaged_timer / DAMAGED_EFF_T, 0.5)
	for i in sprites:
		i.material.set_shader_param('k', k)
	
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

var Bullet = preload("res://Scenes/rocket.tscn")

func shoot():
	shoot_timer = ATTACK_TIMEOUT
	current_gun+=1
	get_node("gun/sprite/gun"+str(current_gun)+'/anim').play('shoot')

	
	var b = Bullet.instance().init(Vector2(1,0).rotated(gun.global_rotation + (randf()-0.5)*SHOOT_RAND))
	get_parent().add_child(b)
	b.global_position = get_node('gun/shoot_points/p'+str(current_gun)).global_position
	current_gun = (current_gun) % count_guns

func get_damage(dmg):
	self.health -= dmg
	_damaged_timer = DAMAGED_EFF_T