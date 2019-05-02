extends Node2D

onready var pointer = $pointer

onready var player_units = $units.get_children()

onready var cursor = $cursor

var current = 0 
var current_unit = null

func next_unit():
	current = (1 + current) % len(player_units)
	current_unit = player_units[current]

func _ready():
	current_unit = player_units[current]

func _process(delta):
	
	pointer.global_position = current_unit.global_position
	cursor.global_position = get_global_mouse_position()
	
	if current_unit.can_move():
		current_unit.look_at(cursor.global_position)
		if current_unit.is_free_move_to(cursor.global_position):
			
			$cursor.modulate.a = 1
			if Input.is_action_just_pressed("click"):
				current_unit.move_to(cursor.global_position)
				next_unit()
		else:
			$cursor.modulate.a = 0.5
	else:
		 $cursor.modulate.a = 0