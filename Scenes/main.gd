extends Node2D

var _chunk_path = ['chunk_start', 'forest_road', #'forest1', 
	'gen1', 'gen1', 'gen1', 
	'gen2', 'gen2', 'gen2', 'forest1', 'forest2','forest1', 'gen1', 'gen1']
var _chunk_types = {}
var _connect_points = null

var _chunk_classes = {
	"gen_forest": preload("res://Scenes/Chunks/gen_forest.tscn"),
	"forest1": preload("res://Scenes/Chunks/forest1.tscn"),
	'forest2': preload("res://Scenes/Chunks/forest2.tscn"),
	"chunk_start": preload("res://Scenes/Chunks/chunk_start.tscn")
}

#onready var player_units = $units.get_children()

onready var cursor = $cursor


signal game_over

#var current = 0
#var current_unit = null

const CHUNKS_BUFFER_SIZE = 4
var chunks = []
var current_chunk = null
var current_chunk_i = 0
var chunks_offset_i = 0

var bg_grad_colors = [Color8(108, 157, 154), Color8(108, 132, 157), Color8(120, 108, 157)]

var bg_grad = []
var bg_grad_size = Vector2()
var bg_grad_current = 0
var bg_grad_offset_i = 0

const BORDER_SIZE = 512

func _ready():
	Input.set_custom_mouse_cursor(preload("res://Sprites/cursor/target.png"), Input.CURSOR_ARROW, Vector2(32,32))
	$UI/white_screen.show()
	
	global.main = self
	global.player = $player
	$player.connect('dead', self, '_on_player_death')
	
	randomize()

	#set up chunks
	var normal_size = Vector2(1024, 600)
	var border_size = BORDER_SIZE
	$bg.position.x = -border_size
	
	
	$chunks.position.x = -border_size
	
	var t = {"class": "gen_forest"}
	t["min_border_size"] = border_size
	t["size"] = normal_size + Vector2(1, 0)*border_size*2
	t["width"] = t["size"].x / 6
	t["rand_delta"] = 50
	
	t["min_items"] = 0
	t["max_items"] = 4
	t["items_probs"] = {'grass':1}
	
	_chunk_types["forest_road"] = t
	
	t = _chunk_types["forest_road"].duplicate()
	t["min_items"] = 1
	t["max_items"] = 6
	t["items_probs"] = {'trunk':2, 'bush':3, 'grass':1}
	
	_chunk_types["gen1"] = t
	
	t = _chunk_types["gen1"].duplicate()
	t["min_items"] = 3
	t["max_items"] = 7
	t["items_probs"] = {'trunk':2, 'bush':3, 'enemy_runner': 3, 'grass':1}
	
	_chunk_types["gen2"] = t
	
#	t = {'class':'forest1'}
#	t["min_border_size"] = border_size
#
#	_chunk_types["forest1"] = t
#
#	t = {'class':'forest2'}
#	t["min_border_size"] = border_size
#
#	_chunk_types["forest2"] = t
#
#	t = {'class':'chunk_start'}
#	t["min_border_size"] = border_size
#
#	_chunk_types["chunk_start"] = t
	
	_connect_points = [border_size, normal_size.x + border_size]
	
	chunks.append(get_next_chunk())
	current_chunk = chunks[0]
	chunks[0].position.y = 0
	$chunks.add_child(chunks[0])
	
	chunks.append(get_next_chunk())
	chunks[1].position.y = -chunks[1].size.y
	$chunks.add_child(chunks[1])
	# bg grad setup
	bg_grad_size = normal_size*Vector2(1, 2.2) + Vector2(1, 0)*border_size*2
	for i in range(len(bg_grad_colors)):
		bg_grad.append(create_bg_grad(i))
# warning-ignore:return_value_discarded
	connect("game_over", self, '_on_game_over')
	_on_screen_resize()
# warning-ignore:return_value_discarded
	get_tree().connect("screen_resized", self, "_on_screen_resize")

func camera_shake(pwr):
	$camera_control.shake(pwr)

func _on_player_death():
	global.player = null
	emit_signal("game_over")

#func _on_player_unit_death(p):
#	var i = player_units.find(p)
#	if current > i:
#		current -= 1
#	elif current == i:
#		next_unit()
#	player_units.erase(p)
#
#	if player_units.size() == 0:
#		emit_signal("game_over")

const GAMEOVER_TIME = 1.5
var gameover_timer = 0

func _on_game_over():
	gameover_timer = GAMEOVER_TIME

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
	$camera_control/camera.zoom = Vector2.ONE * (abs(k)*0.1*sign(k) + 1)

#func next_unit():
#	current = (1 + current) % len(player_units)
#	current_unit = player_units[current]


func _process(delta):
#	if player_units.size() > 0:
#		unit_control_process(delta)
#	else:
#		pointer.hide()
	chunks_generator_update()
	bg_grad_update()
	
	if gameover_timer > 0:
		gameover_timer = max(gameover_timer - delta, 0)
		$UI/white_screen.color.a = 1 - gameover_timer / GAMEOVER_TIME
		if gameover_timer == 0:
			get_tree().reload_current_scene()

# warning-ignore:unused_argument
#func unit_control_process(delta):
#	pointer.global_position = current_unit.global_position
#	pointer_circle.radius = current_unit.RUN_DISTANCE
#	var cpos = get_global_mouse_position()
#
#	var obj = $cursor/damage_area.get_overlapping_bodies()
#	obj = null if obj.size() == 0 else obj[0]
#
#	if obj != null and current_unit.can_target(obj):
#
#		$sticky_cursor.global_position = obj.global_position
#		$sticky_cursor.modulate.a = 1;
#		self.cursor_type = CURSOR_TYPE.TARGET
#
#		if Input.is_action_just_pressed("click"):
#			current_unit.attack_to(obj)
#			next_unit()
#
#	elif current_unit.can_move():
#
#		var h = get_hiding_point(cpos, current_unit.OFFSET_SIZE)
#
#		if h:
#			cpos = h.to_global(current_unit.OFFSET_SIZE)
#
#			if h.owned_by != null or not no_wall_on_path(current_unit.global_position, cpos):
#				self.cursor_type = CURSOR_TYPE.DENIED
#			else:
#				$sticky_cursor.global_position = cpos
#				var x = h.parent.get_parent().block_propability
#				$sticky_cursor.modulate.a = 2*x - x*x
#				self.cursor_type = CURSOR_TYPE.HIDE
#
#				if Input.is_action_just_pressed("click"):
#					current_unit.hide_at(h)
#					next_unit()
#
#		elif current_unit.is_free_move_to(cpos) and no_wall_on_path(current_unit.global_position, cpos):
#			self.cursor_type = CURSOR_TYPE.NORMAL
#			if Input.is_action_just_pressed("click"):
#				current_unit.move_to(cpos)
#				next_unit()
#		else:
#			self.cursor_type = CURSOR_TYPE.DENIED
#
#		current_unit.look(cpos)
#		pointer_circle.show()
#	else:
#		pointer_circle.hide()
#
#	cursor.global_position = get_global_mouse_position()
#
#func current_unit_can_move_to_cursor():
#	return current_unit.is_free_move_to(cursor.global_position) and no_wall_on_path(current_unit.global_position, cursor.global_position)

func get_hiding_point(pos, offset):
	var hide_areas = cursor.get_node('hide_area').get_overlapping_areas()
	if hide_areas.size() == 0:
		return null
	
	var min_d
	var min_p
	
	for h in hide_areas:
		var p = h.get_nearest_free_point_to(pos)
		if p:
			var d = pos.distance_to(p.to_global(offset))
			if min_d == null or (min_d > d):
				min_d = d
				min_p = p
	
	if min_d and min_d > $cursor/hide_area/CollisionShape2D.shape.radius:
		return null
	return min_p

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
			var c = get_next_chunk()
			chunks[nn % CHUNKS_BUFFER_SIZE] = c
			c.position.y = chunks[next_i % CHUNKS_BUFFER_SIZE].position.y-c.size.y
			$chunks.add_child(c)
			
			
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

var _next_chunk = null

func get_next_chunk():
	var fallback_type = "forest_road"
	
	if _next_chunk == null:
		var type = fallback_type
		if _chunk_path.size() > 0:
			type = _chunk_path.pop_front()
		
		_next_chunk = create_chunk(type)
	
	var g = _next_chunk
	if _connect_points[0] == g.start_points[0] and _connect_points[1] == g.start_points[1]:
		_next_chunk = null
	else:
		g = create_chunk(fallback_type, g.start_points)
	
	_connect_points = g.finish_points
	return g
	
func create_chunk(type, finish_points=null):
	var t
	var c
	if type in _chunk_types:
		t = _chunk_types[type]
		c = _chunk_classes[t["class"]]
	elif type in _chunk_classes:
		t = {"min_border_size": BORDER_SIZE}
		c = _chunk_classes[type]
	else:
		assert(false)#Unknown type

	var g = c.instance()
		
	g.create(_connect_points, finish_points, t, get_tree())
	
	return g

onready var wall_check_ray = $wall_check

func no_wall_on_path(u, p1, p2):
	if p1.distance_to(p2) < 2:
		return false
	wall_check_ray.global_position = p1
	wall_check_ray.cast_to = (p2 - p1).normalized()*((p2 - p1).length() + u.OFFSET_SIZE)
	
	wall_check_ray.force_raycast_update()
	return not wall_check_ray.is_colliding()