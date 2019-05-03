extends Node2D

var _chunk_types = {}
var _connect_points = null

var _chunk_classes = {
	"gen_forest": preload("res://Scenes/Chunks/gen_forest.tscn")
}

onready var player_units = $units.get_children()

onready var cursor = $cursor
onready var pointer = $pointer

var current = 0
var current_unit = null

var chunks = []
var current_chunk = null
var current_chunk_i = 0

func _ready():
	randomize()
	current_unit = player_units[current]
	
	var border_size = 128
	var normal_size = get_viewport_rect().size
	
	$chunks.position.x = -border_size
	
	var t = {"class": "gen_forest"}
	t["min_border_size"] = border_size
	t["size"] = normal_size + Vector2(1, 0)*border_size*2
	t["width"] = t["size"].x / 7
	t["rand_delta"] = 50
	
	_chunk_types["forest_road"] = t
	
	t = _chunk_types["forest_road"].duplicate()
	t["min_n_trunk"] = 0
	t["max_n_trunk"] = 3
	_chunk_types["free_forest"] = t
	
	_connect_points = [border_size, normal_size.x + border_size]
	
	chunks.append(create_chunk('forest_road'))
	current_chunk = chunks[0]
	chunks[0].position.y = 0
	chunks.append(create_chunk('free_forest'))

func next_unit():
	current = (1 + current) % len(player_units)
	current_unit = player_units[current]


func _process(delta):
	unit_control_process(delta)
	chunks_generator_update()
		

# warning-ignore:unused_argument
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

func chunks_generator_update():
	if not (current_chunk and current_chunk.has_point($camera_control.global_position)):
		
		var next_i = current_chunk_i + sign(current_chunk.global_position.y - $camera_control.global_position.y)
		
		if next_i+1 == chunks.size():
			chunks.append(create_chunk("free_forest", chunks[chunks.size() - 1].position.y))
			
		
		current_chunk_i = next_i
		current_chunk = chunks[current_chunk_i]

func create_chunk(type, base_y=0):
	var t = _chunk_types[type]
	var g = _chunk_classes[t["class"]].instance()
	
	g.create(_connect_points, t)
	$chunks.add_child(g)
	
	_connect_points = g.finish_points
		
	g.position.y = base_y-g.size.y
	
	return g

onready var wall_check_ray = $wall_check

func no_wall_on_path(p1, p2):
	wall_check_ray.global_position = p1
	wall_check_ray.cast_to = p2 - p1
	
	wall_check_ray.force_raycast_update()
	return not wall_check_ray.is_colliding()