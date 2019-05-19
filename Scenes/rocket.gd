extends "res://Scenes/bullet.gd"

func _ready():
	SPEED = 1800/3
	damage = 4
	Destroy = preload("res://Scenes/rocket_destroy.tscn")
	#collision_mask &= ~2