extends "res://Scenes/Chunks/Chunk.gd"

var TreeFG = preload("res://Scenes/tree.tscn")
const tree_size = 75

# warning-ignore:unused_argument
# warning-ignore:unused_argument
func create(connect_points, finish_points, props, TREE):
	if has_node('kaps'):
		$kaps.rotation = randf()*TAU
		$box.rotation = randf()*TAU
	
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
		
	move_borders_to_shadow()

func _ready():
	if has_node('units'):
		for u in $units.get_children():
			var p = u.global_position
			$units.remove_child(u)
			
			global.main.add_child(u)
			u.global_position = p
		$units.queue_free()