extends Area2D

class HidePoint:
	var pos
	var normal
	var owned_by
	var parent
	signal owned(last, new)
	func _init(parent, pos, normal):
		self.normal = normal.normalized()
		self.pos = pos
		owned_by = null
		self.parent = parent
	func is_free():
		return owned_by == null
	func to_global(offset:float)->Vector2:
		return parent.to_global(pos + offset*normal)
	func own(obj=null):
		emit_signal("owned", owned_by, obj)
		owned_by = obj
	
var points = []

func _ready():
	var ignore_parent = get_parent().is_in_group('obstacle')
	for p in $unit_poses.get_children():
		var h = HidePoint.new(self, p.position, Vector2(1,0).rotated(p.rotation))
		points.append(h)
		if ignore_parent:
			h.connect('owned', self, '_on_point_own')
	
	$unit_poses.queue_free()

func _on_point_own(p, n):
	if p:
		p.remove_ignore(get_parent())
	if n:
		n.add_ignore(get_parent())

func get_nearest_free_point_to(pos):
	var min_d
	var min_p
	var d1 = global_position - pos
	for p in points:
		var d = (d1 + p.pos).length()
		if p.is_free() and (min_p == null or d < min_d):
			min_d = d
			min_p = p
	return min_p

