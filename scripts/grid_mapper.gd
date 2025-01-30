extends Object
class_name GridMapper

const SQRT3 = sqrt(3)
var settings : GenerationSettings


func calculate_map_positions(in_settings: GenerationSettings) -> MappingData:
	settings = in_settings
	var map = MappingData.new()
	var positions : Array[PositionData]
	var min_noise = 999999.0
	var max_noise = -999999.0

	match settings.map_shape:
		0:
			positions = generate_map(hexagonal_bounds(), false, hexagonal_buffer_filter)
			map.staggered_columns = false
		1:
			positions = generate_map(rectangle_bounds(), true, rectangular_buffer_filter)
			map.staggered_columns = true
		2:
			positions = generate_map(diamong_bounds(), true, diamond_buffer_filter, diamond_shape_filter)
			map.staggered_columns = true
		3:
			positions = generate_map(circular_bounds(), true, circular_buffer_filter, circle_shape_filter)
			map.staggered_columns = true

	## Remember the min and max noise generated as this is important for matching noise and weights later
	for pos in positions:
		if pos.noise < min_noise:
			min_noise = pos.noise
		if pos.noise > max_noise:
			max_noise = pos.noise

	map.positions = positions
	map.noise_data = Vector2(min_noise, max_noise)
	return map


func generate_map(loop_bounds: Callable, stagger: bool, buffer_filter: Callable, shape_filter: Callable = Callable()) -> Array[PositionData]:
	var map_data: Array[PositionData] = []
	
	for c in loop_bounds.call():
		for r in loop_bounds.call(c):
			if shape_filter and not shape_filter.call(c, r):
				continue
			var pos = PositionData.new()
			if buffer_filter.call(c, r, settings.radius - settings.map_edge_buffer):
				pos.buffer = true
			pos.world_position = tile_to_world(c, r, stagger)
			pos.grid_position = Vector2(c, r)
			pos.noise = noise_at_tile(c, r)
			map_data.append(pos)
	return map_data


## Get the world position for flat-side hexagons
func tile_to_world(col: int, row: int, stagger: bool) -> Vector3:
	var x: float = 3.0 / 2.0 * col  # Horizontal spacing
	var z: float
	if stagger:
		z = row * SQRT3 + ((col % 2 + 2) % 2) * (SQRT3 / 2)
	else:
		z = (row * SQRT3 + (col * SQRT3 / 2))
	return Vector3(x * settings.tile_size, 0, z * settings.tile_size)


## Get noise at position of tile
func noise_at_tile(x, z) -> float:
	var point_value : float = settings.noise.get_noise_2d(x, z)
	return (point_value + 1) / 2 # normalize [0, 1]

###
### Bounds
### # Specific bounds functions for each shape

func hexagonal_bounds() -> Callable:
	return func(col = null):
		if col == null:
			return range(-settings.radius, settings.radius + 1)
		else:
			return range(max(-settings.radius, -col - settings.radius), min(settings.radius, -col + settings.radius) + 1)


func rectangle_bounds() -> Callable:
	return func(col = null):
		return range(-settings.radius, settings.radius + 1)


func diamong_bounds() -> Callable:
	return func(col = null):
		return range(-settings.radius, settings.radius + 1)


func circular_bounds() -> Callable:
	return func(col = null):
		return range(-settings.radius, settings.radius + 1)

###
### Filters
### # Filters positions to keep only tiles inside a shape

func circle_shape_filter(col: int, row: int) -> bool:
	var dist = sqrt(col * col + row * row)
	return dist <= settings.radius


func diamond_shape_filter(col: int, row: int) -> bool:
	var adjusted_row = row
	if col % 2 != 0:
		adjusted_row += 0.5 
	return abs(adjusted_row) + abs(col) <= settings.radius


###
### Buffer-filters!
### Filter out buffer tiles

func hexagonal_buffer_filter(col: int, row: int, limit: int) -> bool:
	return abs(col + row) > limit or abs(col) > limit or abs(row) > limit


func rectangular_buffer_filter(col: int, row: int, limit: int) -> bool:
	return abs(col) >= limit or abs(row) >= limit


func diamond_buffer_filter(col: int, row: int, limit: int) -> bool:
	return abs(row) + abs(col) > limit


func circular_buffer_filter(col: int, row: int, limit: int) -> bool:
	return col * col + row * row > limit * limit
