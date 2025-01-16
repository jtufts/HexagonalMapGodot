extends Node
class_name ObjectPlacer

@export var village : PackedScene

func place_villages(tiles : Array[Tile], villages_count : int, spacing : int):
	var tiles_copy = tiles.duplicate(true) #copy tiles and leave original unaffected
	var placed_positions = []
	var current_index = 0	
	tiles_copy.shuffle()
	
	while placed_positions.size() < villages_count and current_index < tiles_copy.size():
		# Select random tile from array
		var candidate = tiles_copy[current_index]
		current_index += 1
		var valid = true
		
		# check against previous villages
		for pos : Vector2 in placed_positions:
			var placed_col = pos.x
			var placed_row = pos.y
			if abs(placed_col - candidate.column) <= spacing and abs(placed_row - candidate.row) <= spacing:
				valid = false
				break
				
		if valid:
			placed_positions.append(Vector2(candidate.column, candidate.row))
			spawn_on_tile(candidate, village)

	print("placed " + str(placed_positions.size()) + " villages out of requested " + str(villages_count))
	print("Performed " + str(current_index) + " attempts to find tiles for villages.")


# Spawn a unit at a specific tile
func spawn_on_tile(tile : Tile, scene : PackedScene):
	if not tile or not scene:
		push_warning("tile not found!")
		return

	var instance = scene.instantiate()
	add_child(instance)
	call_deferred("position_object", instance, tile.global_position)


func position_object(object : Node3D, target_location : Vector3):
	object.position = target_location
