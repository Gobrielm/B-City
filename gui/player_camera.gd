class_name PlayerCamera extends Camera2D

static var singleton_instance: PlayerCamera = null

var current_rotation: int = 0
const rotation_90: Transform2D = Transform2D(1.57079632679, Vector2(0, 0))

var city_grid: Dictionary[Vector2i, TileInfo] = {}
var city_layers: Array[TileMapLayer] = []

static func get_instance() -> PlayerCamera:
	assert(singleton_instance != null, "Camera has not been created yet")
	return singleton_instance

# --- Variables ---
var is_panning: bool = false
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.1
@export var max_zoom: float = 5.0

func _ready() -> void:
	singleton_instance = self
	$CanvasLayer.offset = (get_viewport_rect().size / 2.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = event.pressed
		
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_camera(zoom_speed)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_camera(-zoom_speed)

	if event is InputEventMouseMotion and is_panning:
		# We multiply by zoom so that panning feels consistent 
		# regardless of how far zoomed in/out you are.
		position -= event.relative * 1.0/zoom

func zoom_camera(delta: float) -> void:
	var new_zoom: float = clamp(zoom.x + delta, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)

func rotate_camera_by_90() -> void:
	position = Vector2(
		-position.y,
		position.x
	)

func set_screen_with_center_position(pos: Vector2) -> void:
	position = pos

func set_mouse_coords_label(tile: Vector2i) -> void:
	$CanvasLayer/MosueCoordsLabel.text = "Mouse Coords: " + str(tile)

func set_camera_coords_label(tile: Vector2i) -> void:
	$CanvasLayer/CameraCoordsLabel.text = "Camera Coords: " + str(tile)
