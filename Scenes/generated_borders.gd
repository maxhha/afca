extends StaticBody2D

var finish_points 
var start_points 

func generate(
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
		while np < min_x or np > max_x:
			np = pos + (randf() * 2 - 1) * rand_delta
		
		pos = np
		var k = 1 - float(i) / (count_points - 1)
		right[right.size() - 1 - i].x += pos*k
	
	$p_left.polygon = left
	$left.polygon = left
	$p_right.polygon = right
	$right.polygon = right
	
	self.finish_points = finish_points
	self.start_points = start_points