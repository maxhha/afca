extends KinematicBody2D

const AIM_TIME = 2
const STAND_TIME = 2

enum STATES {STAND, AIM}

var STATE = STATES.STAND
var timer = 0

func _ready():
	timer = randf() * STAND_TIME

func _process(delta):
	#logic
	
	#update
	match STATE:
		STATES.STAND:
			if timer > 0:
				timer = max(0, timer - delta)
				if timer == 0 and is_hiding():
					STATE = STATES.AIM
			else:
				timer = STAND_TIME
		STATES.AIM:
			if timer > 0:
				timer = max(0, timer - delta)
				if timer == 0:
					STATE = STATES.STAND
			else:
				timer = AIM_TIME
	#sprite 
	match STATE:
		STATES.STAND:
			if is_hiding():
				$sprite.modulate.a = 0.2
				$detect_shot.hide()
			else:
				$sprite.modulate.a = 1
				$detect_shot.show()
		STATES.AIM:
			$sprite.modulate.a = 1
			$detect_shot.show()

var hiding = false

func is_hiding():
	return hiding

func _on_hide_area_area_entered(area):
	hiding = true

func _on_hide_area_area_exited(area):
	if $hide_area.get_overlapping_areas().size() == 0:
		hiding = false