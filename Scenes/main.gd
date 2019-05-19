extends Node2D
 
var _chunk_path = ['chunk_start', 'forest_road', 
	'gen1', 'gen2', 'gen3', 'gen2','gen3',"forest_road", "gen4","gen4", "repear1", 'forest_road', 
	'gen2', 'gen3', 'gen3',"forest_road", "gen3", "gen4","gen4","gen4", "repear2", 'forest_road', 
	'gen3', 'gen3', 'gen4','gen3', 'gen4', "forest_road", "forest_road", "gen5", "gen5","gen6", "repear2", 'forest_road', 
	'gen4', 'gen3', 'gen3', 'gen3', "gen5", "gen5","gen6", "gen6", "repear3", 'forest_road', 
	"gen6", "gen6", "gen5", "gen5", "gen7", "gen7",
	"repear3",'forest_road',
	'chunk_boss', 'forest_road', 'forest_road'
	]
var _chunk_types = {}
var _connect_points = null

var _chunk_classes = {
	"gen_forest": preload("res://Scenes/Chunks/gen_forest.tscn"),
	"repear1": preload("res://Scenes/Chunks/repear1.tscn"),
	"repear2": preload("res://Scenes/Chunks/repear2.tscn"),
	"repear3": preload("res://Scenes/Chunks/repear3.tscn"),
	"chunk_start": preload("res://Scenes/Chunks/chunk_start.tscn"),
	"chunk_boss": preload("res://Scenes/Chunks/chunk_boss.tscn")
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

const BORDER_SIZE = 1024

func _ready():
	$UI/progress.value = 0
	$UI/progress.max_value = _chunk_path.size() - 2
	Input.set_custom_mouse_cursor(preload("res://Sprites/cursor/target.png"), Input.CURSOR_ARROW, Vector2(32,32))
	$UI/white_screen.show()
	$audio.play(global.bg_music_offset)
	global.main = self
	global.player = $player
# warning-ignore:return_value_discarded
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
	
	t["min_items"] = 2
	t["max_items"] = 5
	t["items_probs"] = {'grass':1}
	
	_chunk_types["forest_road"] = t
	
	t = _chunk_types["forest_road"].duplicate()
	t["min_items"] = 1
	t["max_items"] = 6
	t["items_probs"] = {'trunk':2, 'bush':3, 'grass':1}
	
	_chunk_types["gen1"] = t
	
	t = _chunk_types["gen1"].duplicate()
	t["min_items"] = 2
	t["max_items"] = 7
	t["items_probs"] = {'trunk':2, 'bush':3, 'enemy_runner': 3, 'grass':1}
	
	_chunk_types["gen2"] = t
	
	
	t = _chunk_types["gen1"].duplicate()
	t["min_items"] = 3
	t["max_items"] = 8
	t["items_probs"] = {'trunk':2, 'wall':1, 'enemy_runner': 5, 'grass':1, 'bush':2 }
	
	_chunk_types["gen3"] = t
	
	t = _chunk_types["gen1"].duplicate()
	t["min_items"] = 4
	t["max_items"] = 8
	t["items_probs"] = {'trunk':2, 'wall':2, 'enemy_runner': 5, 'enemy_gunner': 2, 'grass':1, 'bush':1}
	
	_chunk_types["gen4"] = t
	
	t = _chunk_types["gen1"].duplicate()
	t["size"] = _chunk_types["gen1"]['size']*Vector2(1, 1.3)
	t["min_items"] = 5
	t["max_items"] = 9
	t["items_probs"] = {'trunk':2, 'wall':4, 'enemy_runner': 6, 'enemy_gunner': 3, 'enemy_rocket': 1, 'grass':1}
	
	_chunk_types["gen5"] = t
	
	t = _chunk_types["gen5"].duplicate()
	t["min_items"] = 6
	t["max_items"] = 9
	t["items_probs"] = {'trunk':1, 'wall':4, 'enemy_runner': 3, 'enemy_gunner': 3, 'enemy_rocket': 2}
	
	_chunk_types["gen6"] = t
	
	t = _chunk_types["gen6"].duplicate()
	t["min_items"] = 10
	t["max_items"] = 18
	t["items_probs"] = {'wall':4, 'enemy_runner': 3, 'enemy_gunner': 3, 'enemy_rocket': 2}
	
	_chunk_types["gen7"] = t
	
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

const GAMEOVER_TIME = 3
var gameover_timer = 0

func _on_game_over():
	$audio.play(0.5)
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
			global.bg_music_offset = $audio.get_playback_position()
# warning-ignore:return_value_discarded
			get_tree().reload_current_scene()
	
	if $UI/control.visible and Input.is_action_just_pressed('up'):
		$UI/control.hide()
	
	if Input.is_action_just_pressed('sound'):
		var i = AudioServer.get_bus_index('Sound')
		AudioServer.set_bus_mute(i, not AudioServer.is_bus_mute(i))
	if Input.is_action_just_pressed('music'):
		var i = AudioServer.get_bus_index('Music')
		AudioServer.set_bus_mute(i, not AudioServer.is_bus_mute(i))
	
	if can_reload and Input.is_action_pressed('click'):
		global.bg_music_offset = $audio.get_playback_position()
# warning-ignore:return_value_discarded
		get_tree().reload_current_scene()
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()

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
		
		if chunks_offset_i > 0:
			$wall.global_position.y = chunks[chunks_offset_i % CHUNKS_BUFFER_SIZE].global_position.y
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
#			print(type)
			$UI/progress.value = max(0, $UI/progress.max_value - _chunk_path.size())
		else:
			if not $UI/end_game/anim.is_playing() and not can_reload:
				$audio.play(0.5)
				$UI/end_game/anim.play("show")
# warning-ignore:return_value_discarded
				$UI/end_game/anim.connect("animation_finished", self, "_on_finish_game")
		_next_chunk = create_chunk(type)
	
	var g = _next_chunk
	if _connect_points[0] == g.start_points[0] and _connect_points[1] == g.start_points[1]:
		_next_chunk = null
	else:
		g = create_chunk(fallback_type, g.start_points)
	
	_connect_points = g.finish_points
	return g

var can_reload = false

# warning-ignore:unused_argument
func _on_finish_game(a):
	can_reload = true

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
