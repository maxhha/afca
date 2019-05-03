extends Node2D

var _border_types = {}
var _connect_points = null

var _border_classes = {
	"generated": preload("res://Scenes/generated_borders.tscn")
}

onready var player_units = $units.get_children()

onready var cursor = $cursor
onready var pointer = $pointer

var current = 0
var current_unit = null

var walls = []
var current_borders = null
var current_borders_i = 0

func _ready():
	randomize()
	current_unit = player_units[current]
	
	var border_size = 128
	var normal_size = get_viewport_rect().size
	
	$walls.position.x = -border_size
	
	var t = {"class": "generated"}
	t["min_border_size"] = border_size
	t["size"] = normal_size + Vector2(1, 0)*border_size*2
	t["width"] = t["size"].x / 8
	t["rand_delta"] = 50
	
	_border_types["gen1"] = t
	
	_connect_points = [border_size, normal_size.x + border_size]
	
	walls.append(create_borders('gen1'))
	current_borders = walls[0]
	walls[0].position.y = 0
	walls.append(create_borders('gen1'))

func next_unit():
	current = (1 + current) % len(player_units)
	current_unit = player_units[current]


func _process(delta):
	unit_control_process(delta)
	walls_generator_update()
		

func unit_control_process(delta):
	pointer.global_position = current_unit.global_position
	cursor.global_position = get_global_mouse_position()
	
	if current_unit.can_move():
		current_unit.look_at(cursor.global_position)
		if current_unit.is_free_move_to(cursor.global_position) and no_wall_on_path(current_unit.global_position, cursor.global_position):
			
			$cursor.modulate.a = 1
			if Input.is_action_just_pressed("click"):
				current_unit.move_to(cursor.global_position)
				next_unit()
		else:
			$cursor.modulate.a = 0.2
	else:
		 $cursor.modulate.a = 0

func walls_generator_update():
	if not (current_borders and current_borders.has_point($camera_control.global_position)):
		
		var next_i = current_borders_i + sign(current_borders.global_position.y - $camera_control.global_position.y)
		
		if next_i+1 == walls.size():
			walls.append(create_borders("gen1", walls[walls.size() - 1].position.y))
			
			
		
		current_borders_i = next_i
		current_borders = walls[current_borders_i]

func create_borders(type, base_y=0):
	var t = _border_types[type]
	var g = _border_classes[t["class"]].instance()
	g.create(_connect_points, t)
	
	_connect_points = g.finish_points
		
	$walls.add_child(g)
	g.position.y = base_y-g.size.y
	return g

onready var wall_check_ray = $wall_check

func no_wall_on_path(p1, p2):
	wall_check_ray.global_position = p1
	wall_check_ray.cast_to = p2 - p1
	
	wall_check_ray.force_raycast_update()
	return not wall_check_ray.is_colliding()