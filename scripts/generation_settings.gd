extends Resource
class_name GenerationSettings

enum shape {HEXAGONAL, RECTANGULAR, DIAMOND, CIRCLE}

@export_category("Tiles")
@export var tiles : Array[TileMeshData]
@export var biome_weights : Array[float]
@export var tile_size : float = 1

@export_category("Generation")
@export_range(0, 99, 1) var radius: int = 5
@export var noise : FastNoiseLite
@export var debug = false
@export var map_shape : shape = shape.HEXAGONAL

@export_category("Villages")
@export var spawn_villages = true
@export var map_edge_buffer = 2
@export var spacing = 3
