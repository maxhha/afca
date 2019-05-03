extends KinematicBody2D

func _ready():
	$sprite.region_rect.position.x = randi()%3*$sprite.region_rect.size.x
