extends KinematicBody2D

func get_ignore_objects():
	var list = []
	for p in $hide.points:
		if p.owned_by and p.owned_by.is_hiding():
			list.append(p.owned_by)
	return list