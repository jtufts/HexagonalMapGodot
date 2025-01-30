extends Node

# Constants
const HEX_TILE_COLLIDER = preload("res://assets/Meshes/HexTileCollider.tscn")

# Dependencies
@export var settings : GenerationSettings
@export_category("Dependencies")
@export var object_placer : ObjectPlacer
@export var tile_parent : Node3D

# Variables
var tile_script = preload("res://scripts/tile.gd")
var tile_materials : Array[Material]
var placed_tiles : Array[Tile]

# Test-only!
@export var pfinder : Pathfinder
@export var proto_unit : PackedScene


## Starting point: Generate a random seed, create the tiles, place POI's
func _ready() -> void:
	settings.noise.seed = randi() #New seed for this generation
	generate_world()
	create_starting_units(4)


func create_starting_units(count : int):
	## Test pathfinder
	while count > 0:
		var r_tile : Tile = placed_tiles.pick_random()
		if r_tile.mesh_data.type == Tile.biome_type.Ocean or r_tile.occupier != null:
			continue
		var unit : Unit = proto_unit.instantiate()
		add_child(unit)
		unit.place_unit(r_tile.position, r_tile)
		unit.occupy_tile(r_tile)
		count -= 1


func generate_world():
	var starttime = Time.get_ticks_msec()
	var lasttime = starttime
	
	placed_tiles.clear()
	var mapper = GridMapper.new()
	var positions = mapper.calculate_map_positions(settings)
	print("-- calculate_map_positions took: " + str(Time.get_ticks_msec() - lasttime) + " ms --")
	lasttime = Time.get_ticks_msec()
	
	var map = create_map(positions) #Create map
	placed_tiles.append_array(map)
	print("-- create_map() took: " + str(Time.get_ticks_msec() - lasttime) + " ms --")
	lasttime = Time.get_ticks_msec()
	
	if settings.spawn_villages:
		var placeable = get_placeable_tiles()
		object_placer.place_villages(placeable, settings.spacing)
		print("-- Calculating and placing villages took: " + str(Time.get_ticks_msec() - lasttime) + " ms --")
		lasttime = Time.get_ticks_msec()
	
	pfinder.init_map_info(placed_tiles, positions)
	var endtime = Time.get_ticks_msec()
	print("-- World generation took: " + str(endtime - starttime) + " ms --")


func calculate_biome_weights() -> Array[float]:
	var sum = 0.0
	var cumulative_weights : Array[float]
	for weight in settings.biome_weights:
		sum += weight
		cumulative_weights.append(sum)
	return cumulative_weights


## total tiles placed follows: 3 * radius * radius + 3 * radius + 1
func create_map(map_data : MappingData) -> Array[Tile]:
	var new_map : Array[Tile] = []
	## Calculate weights for choosing tiles/biomes
	var weights = calculate_biome_weights()
	var total = 0.0
	for w in settings.biome_weights:
		total += w
		
	## Create new materials for each tile type/color
	for m in settings.tiles:
		## Allow for shader overrides
		if m.shader_override != null:
			tile_materials.append(m.shader_override)
			continue
		var new_mat = StandardMaterial3D.new()
		new_mat.albedo_color = m.color
		tile_materials.append(new_mat)
		
	## Generate the tiles
	for pos in map_data.positions:
		var new_tile : Tile = tile_at_biome(pos.noise, weights, total, map_data.noise_data)
		init_tile(new_tile, pos)
		new_map.append(new_tile)
		debug_tile(new_tile, pos.grid_position)
			
	print("Tiles placed: " + str(new_map.size()))
	return new_map


## Add tile script, add to group, position and parent
func init_tile(tile : Tile, position : PositionData):
	if not tile.is_in_group("tiles"):
		tile.add_to_group("tiles")

	#Add collider
	var col = HEX_TILE_COLLIDER.instantiate()
	tile.add_child(col)
	col.position = tile.position
	
	# Set up material override
	var mesh_instance: MeshInstance3D = tile.get_child(0) as MeshInstance3D
	if mesh_instance:
		mesh_instance.material_override = tile_materials[tile.mesh_data.index]
	else:
		push_warning("No child of tile - init_tile hexboard.gd")
		
	tile.position = position.world_position
	tile_parent.add_child(tile)
	tile.pos_data = position
	tile.biome = Tile.biome_type.find_key(tile.mesh_data.type)


##Debug and test stuff. Add Labels to show coordinates
func debug_tile(tile : Tile, grid_position : Vector2):
	if not settings.debug:
		return
	#Add a label
	var label = Label3D.new()
	tile.add_child(label)
	label.text = str(grid_position.x) + ", " + str(grid_position.y)
	label.text += "\n" + str(-grid_position.x - grid_position.y)
	label.position.y += 0.4
	tile.debug_label = label


## Function to select a biome tile based on weighted probabilities
func tile_at_biome(local_noise, weights : Array[float], total : float, noisedata : Vector2) -> Tile:
	# Cumulative probabilities
	var selected_biome = 0
	var normalized_noise = ((local_noise - noisedata.x) / (noisedata.y - noisedata.x)) * total
	for i in range(weights.size()):
		if normalized_noise < weights[i]:
			selected_biome = i
			break
	#Select and instantiate
	var data = settings.tiles[selected_biome]
	var biome = data.mesh
	var t = biome.instantiate()
	t.set_script(tile_script)
	t.mesh_data = data
	t.mesh_data.index = selected_biome
	return t as Tile


## Ignore buffer and ocean to send to object placer
func get_placeable_tiles() -> Array[Tile]:
	var placeable_tiles : Array[Tile] = []
	var limit = settings.radius - settings.map_edge_buffer
	for tile : Tile in placed_tiles:
		if tile.pos_data.buffer or tile.mesh_data.type == Tile.biome_type.Ocean:
			continue
		placeable_tiles.append(tile)
	print(str(placeable_tiles.size()) + " placeable tiles")
	return placeable_tiles
