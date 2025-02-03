extends Camera3D

@export_category("Movement")
@export var movespeed = 20
@export var zoomspeed = 2
@export var minzoom = 25.0
@export var maxzoom = 90.0
@export var minheight : float = 10
@export var maxheight : float = 30
var minRot = deg_to_rad(-50.0)
var maxRot = deg_to_rad(-80.0)
@onready var sun: DirectionalLight3D = $"../Scene/DirectionalLight3D"


func _ready() -> void:
	adjust_height()
	adjust_rotation()


func _process(delta: float) -> void:
	move_camera(delta)


func move_camera(delta):
	var move_vector : Vector3 = Vector3.ZERO
	if Input.is_action_pressed("MoveForward"):
		move_vector += Vector3.FORWARD
	if Input.is_action_pressed("MoveBackwards"):
		move_vector += Vector3.BACK
	if Input.is_action_pressed("MoveLeft"):
		move_vector += Vector3.LEFT
	if Input.is_action_pressed("MoveRight"):
		move_vector += Vector3.RIGHT

	if move_vector != Vector3.ZERO:
		move_vector = move_vector.normalized() * movespeed * delta
		position += move_vector


func _input(event: InputEvent) -> void:
	# Check for mouse wheel scrolling
	if event is InputEventMouseButton:
		change_fov(event.button_index)
		adjust_height()
		adjust_rotation()
		adjust_shadows()


func change_fov(index):
	if index == MOUSE_BUTTON_WHEEL_UP:
		fov = max(minzoom, fov - zoomspeed)  # Zoom in by decreasing FOV
	elif index == MOUSE_BUTTON_WHEEL_DOWN:
		fov = min(maxzoom, fov + zoomspeed)  # Zoom out by increasing FOV
	

func adjust_height():
	var new_height = inverse_lerp(minzoom, maxzoom, fov)
	position.y = lerpf(minheight, maxheight, new_height)

func adjust_rotation():
	var new_rot = inverse_lerp(minzoom, maxzoom, fov)
	rotation.x = lerpf(minRot, maxRot, new_rot)


## Test to see if we can turn shadows on or off when getting closer to the scene
func adjust_shadows():
	if fov < 50:
		sun.shadow_enabled = true
	elif sun.shadow_enabled:
		sun.shadow_enabled = false
