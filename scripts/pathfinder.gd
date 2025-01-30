extends Node
class_name Pathfinder

const HEXAGONAL_NEIGHBOR_DIRECTIONS = [
	Vector2(1, 0),
	Vector2(1, -1),
	Vector2(0, -1), 
	Vector2(-1, 0),
	Vector2(-1, 1),
	Vector2(0, 1)
]
# Neighbor directions for even/odd rows
const NEIGHBOR_DIRECTIONS_EVEN = [
	Vector2(1, 0),   # Bottom-right
	Vector2(1, -1),  # Top-right
	Vector2(0, -1),  # Top
	Vector2(-1, -1), # Top-left
	Vector2(-1, 0),  # Bottom-left
	Vector2(0, 1)    # Bottom
]
const NEIGHBOR_DIRECTIONS_ODD = [
	Vector2(1, 0),   # Bottom-right
	Vector2(0, -1),  # Top-right
	Vector2(-1, 0),  # Top
	Vector2(-1, 1),  # Top-left
	Vector2(0, 1),   # Bottom-left
	Vector2(1, 1)    # Bottom
]

var neighbor_positions = HEXAGONAL_NEIGHBOR_DIRECTIONS
var stagger = false

@export var highlight_marker : PackedScene
var world_map : Dictionary = {}
var markers = []


func init_map_info(map : Array[Tile], map_data : MappingData):
	world_map.clear()
	for t in map:
		world_map[Vector2(t.pos_data.grid_position.x, t.pos_data.grid_position.y)] = t
	stagger = map_data.staggered_columns
	print("Pathtfinder initialized")


func find_reachable_tiles(start : Tile, movement_range: int) -> Array[Node3D]:
	var queue = []
	var visited = []
	var reachable_tiles : Array[Node3D]

	# Start from the initial tile
	queue.append({"tile": start, "distance": 0})
	visited.append(Vector2(start.pos_data.grid_position.x, start.pos_data.grid_position.y))

	while queue.size() > 0:
		var current = queue.pop_front()
		var current_tile : Tile = current["tile"]
		var current_distance : int = current["distance"]
		
		if current_distance > movement_range:
			continue
		
		# Add the current tile to the reachable list
		reachable_tiles.append(current_tile)

		var current_pos = current_tile.pos_data.grid_position
		
		if stagger:
			if current_pos.x % 2 == 0:
				neighbor_positions = NEIGHBOR_DIRECTIONS_EVEN
			else:
				neighbor_positions = NEIGHBOR_DIRECTIONS_ODD
		
		# Explore neighbors
		for direction in neighbor_positions:
			var neighbor_coords = Vector2(current_pos.x + int(direction.x), current_pos.y + int(direction.y))
			if not is_tile_valid(neighbor_coords) or visited.has(neighbor_coords):
				continue
			var neighbor_tile = world_map[neighbor_coords]
			queue.append({"tile": neighbor_tile, "distance": current_distance + 1})
			visited.append(neighbor_coords)

	return reachable_tiles


func is_tile_valid(coords : Vector2) -> bool:
	var valid = false
	if coords in world_map:
		var tile = world_map[coords]
		if tile.occupier == null and tile.mesh_data.type != Tile.biome_type.Ocean:
			valid = true
	return valid


func clear_highlight():
	if markers and markers.size() > 0:
		for m in markers:
			m.visible = false


func highlight_tile(selected_nodes: Array[Node3D]):
	#Ensure correct marker count
	var marker_diff = selected_nodes.size() - markers.size()
	for m in range(marker_diff):
		var new_marker = highlight_marker.instantiate()
		add_child(new_marker)
		markers.append(new_marker)
	clear_highlight() # turn all markers invisible
	# Iterate over selected tiles
	for i in range(selected_nodes.size()):
		var marker = markers[i]
		var tile : Tile = selected_nodes[i]
		marker.position = tile.position
		marker.visible = true
