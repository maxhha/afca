extends "res://Scenes/Chunks/Chunk.gd"

var Trunk = preload("res://Scenes/Obstacles/trunk.tscn")
var TreeFG = preload("res://Scenes/tree.tscn")
const trunk_size = 160
const tree_size = 75
const WORK_TIME = 2000# usec

func create(connect_points, finish_points, props, TREE):
	var TIME = OS.get_ticks_usec()
	
	prepeare_chunk(props.get("min_border_size", 1))
	add_shadows()

	var left = $left.polygon
	var right = $right.polygon
	#place borders forest
	var poses = []
	
	var e = 0
	while e < 400:
		var p
		while true:
			p = Vector2(randf(), randf())*Vector2(size.x, count_points-1)
			var b = _soft_get(left, p.y + 2)
			if abs(b.x - GRADIENT_SIZE / 2.0 - p.x) <= GRADIENT_SIZE / 2.0:
				p.y = b.y
				break

		var matches = true
		for t in poses:
			if t.distance_to(p) <= tree_size * 2:
				matches = false
				break

		if matches:
			poses.append(p)
			var t = TreeFG.instance()
			add_child(t)
			t.position = p
			t.rotation = randf() * TAU

		if OS.get_ticks_usec() - TIME >= WORK_TIME:
			yield(TREE, "idle_frame")
			TIME = OS.get_ticks_usec()
			

		e += 1

	# repeat process to right side
	poses = []

	e = 0
	while e < 400:
		var p
		while true:
			p = Vector2(randf(), randf())*Vector2(size.x, count_points-1)
			var b = _soft_get(right, p.y + 2)
			if abs(b.x + GRADIENT_SIZE / 2.0 - p.x) <= GRADIENT_SIZE / 2.0:
				p.y = b.y
				break

		var matches = true
		for t in poses:
			if t.distance_to(p) <= tree_size * 2:
				matches = false
				break

		if matches:
			poses.append(p)
			var t = TreeFG.instance()
			add_child(t)
			t.position = p
			t.rotation = randf() * TAU

		if OS.get_ticks_usec() - TIME >= WORK_TIME:
			yield(TREE, "idle_frame")
			TIME = OS.get_ticks_usec()

		e += 1
#
#	# place trunks
#	var count_trunks = int(rand_range(props.get("min_n_trunk", 0), props.get("max_n_trunk", 0)+1))
#
#	var trunks = []
#
## warning-ignore:unused_variable
#	for i in range(count_trunks):
#		var p_y 
#		var p_x 
#
#		e = 0
#
#		var matches = false
#
#		while not matches and e < 1000:
#			p_y = (randi() % (count_points*2 - 3) + 1) / 2.0
#			var min_x = _soft_get(left, p_y+2).x + trunk_size
#			var max_x = _soft_get(right, p_y+2).x - trunk_size
#			if min_x < max_x:
#				p_x = rand_range(min_x, max_x)
#				p_y = (1 - p_y / (count_points - 1)) * size.y
#				matches = true
#
#				var p = Vector2(p_x, p_y)
#
#				for t in trunks:
#					if t.distance_to(p) <= trunk_size*2:
#						matches = false
#						break
#
#			e += 1
#
#		if e >= 1000:
#			break
#
#		var n = Trunk.instance()
#		add_child(n)
#		n.rotation = randf() * TAU
#		n.position = Vector2(p_x, p_y)
#		trunks.append(Vector2(p_x, p_y))
#
#		if OS.get_ticks_usec() - TIME >= WORK_TIME:
#			yield(TREE, "idle_frame")
#			TIME = OS.get_ticks_usec()
		
	move_borders_to_shadow()