extends KinematicBody2D

func _ready():
	clean_up()

func clean_up():
	$unit_poses.free()
	$normal_border.free()