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

const CHUNKS_BUFFER_SIZE = 5
var chunks = []
var current_chunk = null
var current_chunk_i = 0
var chunks_offset_i = 0

var bg_grad_colors = [Color8(108, 157, 154), Color8(108, 132, 157), Color8(120, 108, 157)]

var bg_grad = []
var bg_grad_size = Vector2()
var bg_grad_current = 0
var bg_grad_offset_i = 0

func _ready():
	randomize()
	current_unit = player_units[current]
	
	#set up chunks
	var normal_size = get_viewport_rect().size
	var border_size = 512
	$bg.position.x = -border_size
	
	
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
	
	# bg grad setup
	bg_grad_size = normal_size*Vector2(1, 2.2) + Vector2(1, 0)*border_size*2
	for i in range(len(bg_grad_colors)):
		bg_grad.append(create_bg_grad(i))
	
	
# warning-ignore:return_value_discarded
	get_tree().connect("screen_resized", self, "_on_screen_resize")


func create_bg_grad(indx):
	var p = Polygon2D.new()
	$bg.add_child(p)
	p.position.y = -indx*bg_grad_size.y
	p.polygon = PoolVector2Array([
		Vector2(0, 0), Vector2(0, bg_grad_size.y), bg_grad_size, Vector2(bg_grad_size.x, 0)
	])
	var c1 = bg_grad_colors[indx % len(bg_grad_colors)]
	var c2 = bg_grad_colors[(indx + 1) % len(bg_grad_colors)]
	p.vertex_colors = PoolColorArray([c2, c1, c1, c2])
	return p

	
func _on_screen_resize():
	var normal_s = Vector2(1024, 600)
	var new_s = get_viewport_rect().size
	var k = 1 / max(new_s.x / normal_s.x, new_s.y / normal_s.y) - 1
	$camera_control/camera.zoom = Vector2.ONE * (abs(k)*0.5*sign(k) + 1)

func next_unit():
	current = (1 + current) % len(player_units)
	current_unit = player_units[current]


func _process(delta):
	unit_control_process(delta)
	chunks_generator_update()
	bg_grad_update()

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
		next_i = int(next_i)
		
		
		if next_i+1 == chunks.size() + chunks_offset_i:
			var nn = next_i+1
			if chunks.size() == CHUNKS_BUFFER_SIZE:
				chunks[nn % CHUNKS_BUFFER_SIZE].queue_free()
				chunks_offset_i += 1
			else:
				chunks.append(null)
			chunks[nn % CHUNKS_BUFFER_SIZE] = create_chunk("free_forest", chunks[next_i % CHUNKS_BUFFER_SIZE].position.y)
		
		current_chunk_i = next_i
		current_chunk = chunks[current_chunk_i % CHUNKS_BUFFER_SIZE]

func bg_grad_update():
	if abs($camera_control.global_position.y - (0.5-bg_grad_current)*bg_grad_size.y) >= bg_grad_size.y / 2:
		var next_i = int(bg_grad_current + sign(- bg_grad_current*bg_grad_size.y - $camera_control.global_position.y))
		if next_i-1 < bg_grad_offset_i:
			var nn = next_i - 1
			bg_grad_offset_i -= 1
			bg_grad[nn % len(bg_grad_colors)].position.y = -nn*bg_grad_size.y
		elif next_i+1 >= bg_grad_offset_i + len(bg_grad_colors):
			var nn = next_i+1
			bg_grad_offset_i += 1
			bg_grad[nn % len(bg_grad_colors)].position.y = -nn*bg_grad_size.y
			
		bg_grad_current = next_i
		

func create_chunk(type, base_y=0):
	var t = _chunk_types[type]
	var g = _chunk_classes[t["class"]].instance()
	$chunks.add_child(g)
	g.create(_connect_points, t)
	
	
	_connect_points = g.finish_points
		
	g.position.y = base_y-g.size.y
	
	return g

onready var wall_check_ray = $wall_check

func no_wall_on_path(p1, p2):
	wall_check_ray.global_position = p1
	wall_check_ray.cast_to = p2 - p1
	
	wall_check_ray.force_raycast_update()
	return not wall_check_ray.is_colliding()