extends Node3D

@export var tile_cursor_scene : PackedScene
@export var unit_cursor_scene : PackedScene
@export var main_camera : Camera3D
@export var p_finder : Pathfinder
var selected_tile : Node3D
var selected_unit : Unit
var unit_moves : Array[Node3D]
# Cursors
var tile_cursor : Node3D
var unit_cursor : Node3D

var current_hover : Node3D


func _ready() -> void:
	if not tile_cursor or tile_cursor == null:
		tile_cursor = tile_cursor_scene.instantiate()
		add_child(tile_cursor)
	if not unit_cursor:
		unit_cursor = unit_cursor_scene.instantiate()
		add_child(unit_cursor)
	deselect()
	
func _input(event: InputEvent) -> void:
	print(event)
	if event is InputEventMouseMotion:
		print(event)
		var mouse_pos = get_viewport().get_mouse_position()
		var origin = main_camera.project_ray_origin(mouse_pos)
		var dir = main_camera.project_ray_normal(mouse_pos)
		var end = origin + dir * 1000
		var hit_object = raycast_at_mouse(origin, end)
		print(hit_object)
		if hit_object != null:
			show_tooltip(hit_object)
		else:
			hide_tooltip()
		#if not not hit_object:
			#print(hit_object.biome)
		#if (current_hover != hit_object):
			#current_hover = hit_object
			#hide_tooltip()
			#show_tooltip(hit_object)
		#if not hit_object:
			#hide_tooltip()
		#else:
			#show_tooltip(hit_object)
	#if event is InputEventMouseButton:
		#var mouse_pos = get_viewport().get_mouse_position()
		#var origin = main_camera.project_ray_origin(mouse_pos)
		#var dir = main_camera.project_ray_normal(mouse_pos)
		#var end = origin + dir * 1000
		#var hit_object = raycast_at_mouse(origin, end)
		#if not hit_object:
			#return
		#if Input.is_action_just_pressed("Click") and event.pressed:
			#attempt_select(hit_object)
		#elif Input.is_action_just_pressed("RightClick"):
			#attempt_move_unit(hit_object)
	


func raycast_at_mouse(origin, end) -> Node3D:
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		var collision = get_world_3d().direct_space_state.intersect_ray(query)
		if collision and collision.has("collider"):
			var hit = collision.collider.get_parent()
			return hit
		else:
			deselect()
			return null


func deselect():
	hide_cursor(tile_cursor)
	hide_cursor(unit_cursor)
	unit_moves.clear()
	selected_unit = null
	p_finder.clear_highlight()


func attempt_select(hit):
	deselect()
	if hit.is_in_group("tiles"):
		highlight_tile(hit)
	elif hit.is_in_group("units"):
		select_unit(hit)


func attempt_move_unit(hit):
	if not selected_unit or not hit.is_in_group("tiles") or hit is not Tile or not unit_moves.has(hit):
		print("Attempted to move to invalid tile")
		return
	selected_unit.place_unit(hit.position, hit)
	deselect()


func select_unit(unit):
	selected_tile = null
	selected_unit = unit
	hide_cursor(tile_cursor)
	if unit is Unit:
		highlight_unit(unit)
		unit_moves = p_finder.find_reachable_tiles(unit.occupied_tile, unit.movement_range)
		p_finder.highlight_tile(unit_moves)


func highlight_tile(tile):
	selected_unit = null
	selected_tile = tile
	hide_cursor(unit_cursor)
	move_cursor(tile_cursor, tile.global_position)
	tile_cursor.visible = true

func highlight_unit(unit):
	move_cursor(unit_cursor, unit.position)
	unit_cursor.visible = true

func show_tooltip(tile):
	%TileLabel.text = tile.biome
	%TileDescription.show()

func hide_tooltip():
	%TileDescription.hide()

## move cursor with optional height difference
func move_cursor(cursor : Node3D, pos : Vector3, height : float = 0):
	cursor.position = pos
	if height != 0:
		tile_cursor.position.y += height


func hide_cursor(cursor : Node3D):
	if cursor:
		move_cursor(cursor, Vector3.ZERO, -10)
		cursor.visible = false
