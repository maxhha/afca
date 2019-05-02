extends Node2D

onready var player_units = $units.get_children()

onready var cursor = $cursor
onready var pointer = $pointer

var current = 0
var current_unit = null

var walls = []

var GeneratedBorders = preload("res://Scenes/generated_borders.tscn")

func _ready():
	randomize()
	current_unit = player_units[current]
	
	var border_size = 128
	var size = get_viewport_rect().size + Vector2(1, 0)*border_size*2
	var width = size.x / 8 
	var delta = 3
	
	var connect_points = [border_size, size.x-border_size]
	
	for i in range(10):
		var g = GeneratedBorders.instance()
		g.generate(size, border_size, width, delta, connect_points, null, 10)
		connect_points = g.finish_points
		
		add_child(g)
		g.position.x = -border_size
		g.position.y = -i*size.y

func next_unit():
	current = (1 + current) % len(player_units)
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
			$cursor.modulate.a = 0.2
	else:
		 $cursor.modulate.a = 0