extends KinematicBody2D

func clean_up():
	$unit_poses.free()
	$normal_border.free()