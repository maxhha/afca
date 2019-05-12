extends "res://Scenes/bullet.gd"

func _ready():
	SPEED = 1800
	damage = 5
	Destroy = preload("res://Scenes/rocket_destroy.tscn")