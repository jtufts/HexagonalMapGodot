extends Node

@export_category("Tiles")
@export var tiles : Array[TileMeshData]
@export var biome_weights : Array[float]
var tile_script = preload("res://scripts/tile.gd")
const HEX_TILE_COLLIDER = preload("res://assets/Meshes/HexTileCollider.tscn")
var tile_materials : Array[StandardMaterial3D]

@export_category("Generation")
@export_range(0, 99, 1) var radius: int = 5
var hex_size : float = 1 # for adjustment and spacing
@export var noise : FastNoiseLite
var min_noise
var max_noise
@export var debug = false

@export_category("Villages")
@export var map_edge_buffer = 2
@export_range(1, 99) var village_density
@export var spacing = 3

@export_category("Dependencies")
@export var object_placer : ObjectPlacer
@export var tile_parent : Node3D

var placed_tiles : Array[Tile]
const SQRT3 = sqrt(3)

## Test only!
@export var pfinder : Pathfinder
@export var proto_unit : PackedScene


## Starting point: Generate a random seed, create the tiles, place POI's
func _ready() -> void:
	noise.seed = randi() #New seed for this generation
	generate_world()
	create_starting_units()


func create_starting_units():
	## Test pathfinder
	var test_units = 5
	while test_units > 0:
		var r_tile : Tile = placed_tiles.pick_random()
		if r_tile.meshdata.type == Tile.biome_type.Ocean or r_tile.occupier != null:
			continue
		var unit : Unit = proto_unit.instantiate()
		add_child(unit)
		unit.place_unit(r_tile.position, r_tile)
		unit.occupy_tile(r_tile)
		test_units -= 1


func generate_world():
	var starttime = Time.get_ticks_msec()
	var lasttime = starttime
	
	placed_tiles.clear()
	var positions = calculate_map_positions()
	print("-- calculate_map_positions took: " + str(Time.get_ticks_msec() - lasttime) + " ms --")
	lasttime = Time.get_ticks_msec()
	
	var map = create_map(positions) #Create map
	placed_tiles.append_array(map)
	print("-- create_map() took: " + str(Time.get_ticks_msec() - lasttime) + " ms --")
	lasttime = Time.get_ticks_msec()
	
	var placeable = get_placeable_tiles()
	var village_count = calculate_villages(placeable.size())
	object_placer.place_villages(placeable, village_count, spacing)
	print("-- Calculating and placing villages took: " + str(Time.get_ticks_msec() - lasttime) + " ms --")
	lasttime = Time.get_ticks_msec()
	
	pfinder.init_map_info(placed_tiles)
	var endtime = Time.get_ticks_msec()
	print("-- World generation took: " + str(endtime - starttime) + " ms --")


func calculate_map_positions() -> Array[position_data]:
	var map : Array[position_data]
	min_noise = 100
	max_noise = 0
	for i in range(-radius, radius+1):
		for j in range(max(-radius, -i - radius), min(radius, -i + radius) + 1):
			var pos = position_data.new()
			pos.world_position = tile_to_world(i, j)
			pos.noise = noise_at_tile(i, j)
			pos.grid_position = Vector2(i,j)
			map.append(pos)
			if pos.noise < min_noise: min_noise = pos.noise
			if pos.noise > max_noise: max_noise = pos.noise
	#print("Min noise: " + str(min_noise) + ". Max noise: " + str(max_noise))
	return map


func calculate_biome_weights() -> Array[float]:
	var sum = 0.0
	var cumulative_weights : Array[float]
	for weight in biome_weights:
		sum += weight
		cumulative_weights.append(sum)
	return cumulative_weights


## total tiles placed follows: 3 * radius * radius + 3 * radius + 1
func create_map(positions_array : Array[position_data]) -> Array[Tile]:
	var new_map : Array[Tile] = []
	## Calculate weights for choosing tiles/biomes
	var weights = calculate_biome_weights()
	var total = 0.0
	for w in biome_weights:
		total += w
		
	## Create new materials for each tile type/color
	for m in tiles:
		var new_mat = StandardMaterial3D.new()
		new_mat.albedo_color = m.color
		tile_materials.append(new_mat)
		
	## Generate the tiles
	for pos in positions_array:
		var new_tile : Tile = tile_at_biome(pos.noise, weights, total)
		init_tile(new_tile, pos.world_position, pos.grid_position)
		new_map.append(new_tile)
		debug_tile(new_tile, pos.grid_position)
			
	print("Tiles placed: " + str(new_map.size()))
	return new_map


## Add tile script, add to group, position and parent
func init_tile(tile : Tile, position : Vector3, grid_position : Vector2i):
	if not tile.is_in_group("tiles"):
		tile.add_to_group("tiles")

	#Add collider
	var col = HEX_TILE_COLLIDER.instantiate()
	tile.add_child(col)
	col.position = tile.position
	
	# Set up material override
	var mesh_instance: MeshInstance3D = tile.get_child(0) as MeshInstance3D
	if mesh_instance:
		mesh_instance.material_override = tile_materials[tile.meshdata.index]
	else:
		push_warning("No child of tile - init_tile hexboard.gd")
		
	tile.position = position
	tile_parent.add_child(tile)
	tile.column = grid_position.x
	tile.row = grid_position.y
	tile.biome = Tile.biome_type.find_key(tile.meshdata.type)


##Debug and test stuff. Add Labels to show coordinates
func debug_tile(tile : Node3D, grid_position : Vector2):
	if not debug:
		return
	#Add a label
	var label = Label3D.new()
	tile.add_child(label)
	label.text = str(grid_position.x) + ", " + str(grid_position.y) 
	label.text += "\n" + str(abs(grid_position.x + grid_position.y))
	label.position.y += 0.25


## Get the world position for flat-side hexagons
func tile_to_world(i : float, j : float) -> Vector3:
	var x : float = hex_size * (i * 3/2)
	var z : float = hex_size * (j * SQRT3 + (i * SQRT3 / 2))
	return Vector3(x, 0, z)


## Get noise from at position of tile
func noise_at_tile(x, z) -> float:
	var point_value : float = noise.get_noise_2d(x, z)
	return (point_value + 1) / 2 # normalize [0, 1]


## Function to select a biome tile based on weighted probabilities
func tile_at_biome(local_noise, weights : Array[float], total : float) -> Tile:
	# Cumulative probabilities
	var selected_biome = 0
	var normalized_noise = ((local_noise - min_noise) / (max_noise - min_noise)) * total
	for i in range(weights.size()):
		if normalized_noise < weights[i]:
			selected_biome = i
			break
	#Select and instantiate
	var data = tiles[selected_biome]
	var biome = data.mesh
	var t = biome.instantiate()
	t.set_script(tile_script)
	t.meshdata = data
	t.meshdata.index = selected_biome
	return t as Tile


func calculate_villages(valid_tiles : int) -> int:
	## calculate roughly the amount of valid tiles and how many villages can be placed
	var initial = int(valid_tiles * (village_density * 0.01))
	
	# Adjust for spacing
	var invalidated = 0
	for r in range(1, spacing + 1):
		invalidated += 6 * r  # Each hexagonal ring has 6 * r tiles
	var adjusted = initial / (1 + invalidated / valid_tiles)

	return max(1, adjusted)  # At least 1 village


## Ignore buffer and ocean to send to object placer
func get_placeable_tiles() -> Array[Tile]:
	var placeable_tiles : Array[Tile] = []
	var limit = radius - map_edge_buffer
	for tile : Tile in placed_tiles:
		if abs(tile.column + tile.row) >= limit or abs(tile.column) >= limit or abs(tile.row) >= limit or tile.meshdata.type == Tile.biome_type.Ocean:
			continue
		placeable_tiles.append(tile)
	print(str(placeable_tiles.size()) + " placeable tiles")
	return placeable_tiles
