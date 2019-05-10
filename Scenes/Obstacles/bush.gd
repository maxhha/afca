extends "res://Scenes/Obstacles/Obstacle.gd"

func _ready():
	$sprite.frame = randi() % $sprite.hframes