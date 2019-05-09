extends KinematicBody2D

const PASS_PROB = 0.5

func get_ignore_objects():
	var list = []
	for p in $hide.points:
		if p.owned_by and p.owned_by.is_hiding():
			list.append(p.owned_by)
	return list

func can_pass(obj):
	return randf() < PASS_PROB