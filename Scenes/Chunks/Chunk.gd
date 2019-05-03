extends StaticBody2D

const DARK_COLOR = Color("000F0F")
const GRADIENT_SIZE = 256
const GRADIENT_Z_INDEX = 1024

var size
var finish_points 
var start_points 
var count_points 

# warning-ignore:unused_argument
# warning-ignore:unused_argument
func create(connect_points, props):
	pass

func generate_borders(
		size : Vector2,
		min_border_size : float,
		width : float,
		rand_delta: float,
		start_points = null,
		finish_points = null,
		count_points: float = 6):
	
	if start_points == null:
		start_points = [null, null]
	
	if finish_points == null:
		finish_points = [null, null]
	
	var left = PoolVector2Array()
	var right = PoolVector2Array()
	
	# generate left side
	left.append(Vector2.ZERO)
	left.append(Vector2(0, size.y))
	
	var pos
	var min_x = min_border_size
	var max_x = size.x - width - min_border_size
	
	# from bottom to top
	if start_points[0]:
		pos = start_points[0]
	else:
		pos = lerp(min_x, max_x, randf())
		start_points[0] = pos
	
	left.append(Vector2(pos, size.y))
	
	for i in range(1, count_points):
		var np = pos + (randf() * 2 - 1) * rand_delta
		while np < min_x or np > max_x:
			np = pos + (randf() * 2 - 1) * rand_delta
		
		pos = np
		
		var k = 1 - float(i) / (count_points - 1)
		left.append(Vector2(pos*k, size.y * k))
		
	
	# and vise versa
	if finish_points[0]:
		pos = finish_points[0]
	else:
		pos = lerp(min_x, max_x, randf())
		finish_points[0] = pos

	left[left.size() - 1].x = pos

	for i in range(1, count_points):
		var np = pos + (randf() * 2 - 1) * rand_delta
		while np < min_x or np > max_x:
			np = pos + (randf() * 2 - 1) * rand_delta
		
		pos = np
		var k = 1 - float(i) / (count_points - 1)
		left[left.size() - 1 - i].x += pos*k
	
	
	
	
	
	# generate right side
	right.append(Vector2(size.x, 0))
	right.append(size)
	
	max_x = size.x - min_border_size
	
	# from bottom to top
	if start_points[1]:
		pos = start_points[1]
	else:
		pos = lerp(left[2].x + width, max_x, randf())
		start_points[1] = pos
	
	right.append(Vector2(pos, size.y))
	
	for i in range(1, count_points):
		min_x = left[2].x + width
		
		var np = pos + (randf() * 2 - 1) * rand_delta
		while np < min_x or np > max_x:
			np = pos + (randf() * 2 - 1) * rand_delta
		
		pos = np
		
		var k = 1 - float(i) / (count_points - 1)
		right.append(Vector2(pos*k, size.y * k))
	
	
	
	# and vise versa
	if finish_points[1]:
		pos = finish_points[1]
	else:
		pos = lerp(left[left.size() - 1].x + width, max_x, randf())
		finish_points[1] = pos

	right[right.size() - 1].x = pos

	for i in range(1, count_points):
		min_x = left[left.size() - 1 - i].x + width
		
		var np = pos + (randf() * 2 - 1) * rand_delta
		var j = 0
		while (np < min_x or np > max_x) and j < 100:
			np = pos + (randf() * 2 - 1) * rand_delta
			j += 1
		
		pos = clamp(np, min_x, max_x)
		var k = 1 - float(i) / (count_points - 1)
		right[right.size() - 1 - i].x += pos*k
	
	$left.polygon = left
	$right.polygon = right
	
	self.count_points = count_points
	self.finish_points = finish_points
	self.start_points = start_points
	self.size = size

func add_shadows(z_index=GRADIENT_Z_INDEX):
	
	var left = $left.polygon
	var right = $right.polygon
	
	var c0 = Color(0,0,0,0)
	var c1 = DARK_COLOR
	
	var c_pool = PoolColorArray([c1, c1, c0, c0, c1, c1])
	
	for i in range(count_points-1):
		# left side
		var pol = Polygon2D.new()
		
		pol.polygon = PoolVector2Array([
			Vector2(0, left[2 + i].y),
			Vector2(left[2 + i].x - GRADIENT_SIZE, left[2 + i].y),
			Vector2(left[2 + i].x, left[2 + i].y),
			Vector2(left[3 + i].x, left[3 + i].y),
			Vector2(left[3 + i].x - GRADIENT_SIZE, left[3 + i].y),
			Vector2(0, left[3 + i].y) 
		])
		pol.vertex_colors = c_pool
		pol.z_index = z_index
		add_child(pol)
		
		# right side
		pol = Polygon2D.new()
		pol.polygon = PoolVector2Array([
			Vector2(size.x, right[2 + i].y),
			Vector2(right[2 + i].x + GRADIENT_SIZE, right[2 + i].y),
			Vector2(right[2 + i].x, right[2 + i].y),
			Vector2(right[3 + i].x, right[3 + i].y),
			Vector2(right[3 + i].x + GRADIENT_SIZE, right[3 + i].y),
			Vector2(size.x, right[3 + i].y) 
		])
		
		pol.vertex_colors = c_pool
		pol.z_index = z_index
		add_child(pol)
	

func has_point(p):
	return (p.x >= global_position.x 
		and p.y >= global_position.y
		and p.x < global_position.x + size.x
		and p.y < global_position.y + size.y)

func _soft_get(ar, i):
	var fi = int(i)
	var ci = int(ceil(i))
	if fi == ci:
		return ar[fi]
	else:
		return ar[fi]*(i - fi) + ar[ci]*(ci - i)

func move_borders_to_shadow():
	var left = $left.polygon
	var right = $right.polygon
	
	for i in range(count_points):
		left[2+i].x -= GRADIENT_SIZE
		right[2+i].x += GRADIENT_SIZE