extends Sprite

var timer = 0.05

func _process(delta):
	timer -= delta
	if timer <= 0:
		queue_free()