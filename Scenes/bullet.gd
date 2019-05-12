extends KinematicBody2D

const MAX_DIST = 2048
const OBSTACLE_BIT = 16
var SPEED = 1800*2

var damage = 1
var linear_vel = Vector2()
var dist = 0

func init(dir, by_player=false):
	if by_player:
		collision_mask |= 8
	else:
		collision_mask |= 2
	rotation = dir.angle()
	linear_vel = SPEED * dir.normalized()
	return self

var Destroy = preload("res://Scenes/bullet_destroy.tscn")

func _physics_process(delta):
	var distance = linear_vel * delta
	dist += distance.length()
	while distance.length() > 0:
		var k = move_and_collide(distance)
		if k:
			distance -= k.travel
			
			if k.collider.is_in_group('unit'):
				k.collider.get_damage(damage)
				
			elif k.collider.is_in_group('obstacle') and k.collider.can_pass(self):
				for o in k.collider.get_ignore_objects():
					add_collision_exception_with(o)
				add_collision_exception_with(k.collider)
				continue
			add_collision_exception_with(k.collider)
			var d = Destroy.instance()
			get_parent().add_child(d)
			d.global_position = global_position
			d.z_index = z_index
			queue_free()
			break
		else:
			break
	
	if  dist > MAX_DIST:
		queue_free()