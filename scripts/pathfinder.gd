extends Node
class_name Pathfinder

const NEIGHBOR_DIRECTIONS = [
	Vector2(1, 0), Vector2(1, -1), Vector2(0, -1), 
	Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1)
]
@export var highlight_marker : PackedScene
var world_map : Dictionary = {}
var markers = []


func init_map_info(map : Array[Tile]):
	world_map.clear()
	for t in map:
		world_map[Vector2(t.column, t.row)] = t
	print("Pathtfinder initialized")


func find_reachable_tiles(start : Tile, movement_range: int) -> Array[Node3D]:
	var queue = []
	var visited = []
	var reachable_tiles : Array[Node3D]

	# Start from the initial tile
	queue.append({"tile": start, "distance": 0})
	visited.append(Vector2(start.column, start.row))

	while queue.size() > 0:
		var current = queue.pop_front()
		var current_tile : Tile = current["tile"]
		var current_distance : int = current["distance"]
		
		if current_distance > movement_range:
			continue
		
		# Add the current tile to the reachable list
		reachable_tiles.append(current_tile)

		var q = current_tile.column
		var r = current_tile.row - (current_tile.column - (int(current_tile.column)%2)) / 2
		print (q, " ", r)
		# Explore neighbors
		for direction in NEIGHBOR_DIRECTIONS:
			print(q + direction.x, " ", r + direction.y + (q + direction.x - (int(q+direction.x)%2)) / 2)
			var neighbor_coords = Vector2(q + direction.x, r + direction.y + (q + direction.x - (int(q + direction.x)%2)) / 2)
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
		if tile.occupier == null and tile.meshdata.type != Tile.biome_type.Ocean:
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
