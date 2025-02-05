extends Node3D
class_name Overlay

enum biome_type {Grassland, Forest, Desert, Ocean, Tundra, Mountain, Snow}
var meshdata : TileMeshData
var column : int
var row : int
var biome : String
var player_owner : int = -1
var borders : Array[int] = [-1, -1, -1, -1, -1, -1]
	
func updateBorders(border_array: Array[int]):
	borders = border_array
	
