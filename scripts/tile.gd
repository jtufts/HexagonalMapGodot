extends Node3D
class_name Tile

enum biome_type {Grassland, Forest, Desert, Ocean, Tundra, Mountain}
var meshdata : TileMeshData
var occupier : Unit
var column : int
var row : int
var biome : String
