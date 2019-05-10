extends KinematicBody2D

export (float) var block_propability = 1

func get_ignore_objects():
	return $hide.get_hiding_objects()

func can_pass(obj):
	return randf() >= block_propability