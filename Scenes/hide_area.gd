extends Area2D

class HidePoint:
	var pos
	var normal
	var angle
	var owned_by
	var parent
	signal owned(last, new)
	func _init(parent, pos, angle):
		self.angle = angle
		self.normal = Vector2(1,0).rotated(angle)
		self.pos = pos
		owned_by = null
		self.parent = parent
	func is_free():
		return owned_by == null
	func to_global(offset):
		return parent.to_global(pos + offset*normal)
	func own(obj=null):
		emit_signal("owned", owned_by, obj)
		owned_by = obj
	func get_rotation():
		return parent.global_transform.basis_xform(normal).angle()
	func get_stand_rotation():
		return parent.global_transform.basis_xform(normal).rotated(PI).angle()
	func match_side(p):
		return parent.to_local(p).dot(normal) >= 0

class SoftHidePoint:
	extends HidePoint
	func _init(parent, pos).(parent, pos, 0):
		pass
# warning-ignore:unused_argument
	func to_global(offset):
		return parent.to_global(pos)
	func get_rotation():
		return owned_by.rotation if owned_by else randf()*TAU
	func get_stand_rotation():
		return get_rotation()
# warning-ignore:unused_argument
	func match_side(p):
		return true

var points = []

func _ready():
	var ignore_parent = get_parent().is_in_group('obstacle')
	for p in $unit_poses.get_children():
		var h
		if p is Position2D:
			h = SoftHidePoint.new(self, p.position)
		else:
			h = HidePoint.new(self, p.position, p.rotation)
		points.append(h)
		if ignore_parent:
			h.connect('owned', self, '_on_point_own')
	
	$unit_poses.queue_free()

func _on_point_own(p, n):
	if p:
		p.remove_ignore(get_parent())
	if n:
		n.add_ignore(get_parent())

func get_nearest_free_point_to(pos, side_pos = null):
	
	var min_d
	var min_p
	var d1 = to_local(pos)
	for p in points:
		var d = (p.pos - d1).length()
		if p.is_free() and (side_pos == null or p.match_side(side_pos)) and (min_p == null or d < min_d):
			min_d = d
			min_p = p
	return min_p
	

func get_hiding_objects():
	var list = []
	for p in points:
		if is_instance_valid(p.owned_by) and p.owned_by.is_in_group('unit') and p.owned_by.is_hiding():
			list.append(p.owned_by)
	return list

func is_owned_by_enemy():

	for em in points:
		if is_instance_valid(em.owned_by) and em.owned_by.is_in_group('enemy'):
			return true
			
	return false