extends KinematicBody2D

export (float) var block_propability = 1
export (bool) var ignore = true

func get_ignore_objects():
	if ignore:
		return $hide.get_hiding_objects() 
	else:
		return []

func can_pass(obj):
	return randf() >= block_propability or obj.z_index > 100