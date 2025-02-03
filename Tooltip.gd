#class_name Tooltip
#extends Node
#
#
#@export var visuals_res: CompressedTexture2D
#@export var owner_node: Node
#
#var _visuals: Control
#
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#add_child(_visuals)
	#owner_node.mouse_entered.connect("_mouse_entered")
	#owner_node.mouse_exited.connect("_mouse_exited")
	#pass # Replace with function body.
#
#func _mouse_entered() -> void:
	#_visuals.show()
#
#func _mouse_exited() -> void:
	#_visuals.hide()
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
