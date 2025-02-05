extends Resource
class_name BorderMeshData

@export var mesh : PackedScene
@export var color : Color

## This is used by world_gen to keep track of which index this tile has in the tiles array
var index = 0
