extends KinematicBody2D

const OBSTACLE_BIT = 16
const SPEED = 600

var damage = 1
var linear_vel = Vector2()

func init(dir, by_player=false):
	if by_player:
		collision_mask |= 8
	else:
		collision_mask |= 2
	rotation = dir.angle()
	linear_vel = SPEED * dir.normalized()
	return self

func _physics_process(delta):
	var distance = linear_vel * delta
	while distance.length() > 0:
		var k = move_and_collide(distance)
		if k:
			distance -= k.travel
			
			if k.collider.is_in_group('unit'):
				k.collider.get_damage(damage)
				
			elif k.collider.is_in_group('obstacle'):
				for o in k.collider.get_ignore_objects():
					add_collision_exception_with(o)
				add_collision_exception_with(k.collider)
				continue
			queue_free()
			break
		else:
			break
			
		
	global_position += linear_vel * delta