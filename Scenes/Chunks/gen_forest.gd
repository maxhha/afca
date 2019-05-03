extends "res://Scenes/Chunks/Chunk.gd"

var Trunk = preload("res://Scenes/trunk.tscn")
const trunk_size = 160

func create(connect_points, props):
	generate_borders(props.get("size"),
		props.get("min_border_size", 1),
		props.get("width", 80),
		props.get("rand_delta", 0),
		connect_points,
		props.get("finish_points"),
		props.get("count_points", 6)
		)
	add_shadows()
	var count_points = props.get("count_points", 6)
	var left = $left.polygon
	var right = $right.polygon
	var count_trunks = int(rand_range(props.get("min_n_trunk", 0), props.get("max_n_trunk", 0)+1))
	
	var trunks = []
	
# warning-ignore:unused_variable
	for i in range(count_trunks):
		var n = Trunk.instance()
		
		var p_y 
		var p_x 
		
		var e = 0
		
		var matches = false
		
		while not matches and e < 1000:
			p_y = (randi() % (count_points*2 - 3) + 1) / 2.0
			var min_x = _soft_get(left, p_y+2).x + trunk_size
			var max_x = _soft_get(right, p_y+2).x - trunk_size
			if min_x < max_x:
				p_x = rand_range(min_x, max_x)
				p_y = (1 - p_y / (count_points - 1)) * size.y
				matches = true
				
				var p = Vector2(p_x, p_y)
				
				for t in trunks:
					if t.distance_to(p) <= trunk_size*2:
						matches = false
						break
				
			e += 1
			
		if e >= 1000:
			n.queue_free()
			return
		
		add_child(n)
		n.rotation = randf() * TAU
		n.position = Vector2(p_x, p_y)
		trunks.append(Vector2(p_x, p_y))

func _soft_get(ar, i):
	return (ar[int(i)] + ar[ceil(i)]) / 2