extends Area2D

func _on_box_body_entered(body):
	global.player.health = global.player.MAX_HEALTH
	queue_free()
