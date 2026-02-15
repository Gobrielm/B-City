class_name RotatableMap extends Node2D

var current_rotation: int = 0
const LAYERS: int = 10
const map_size = Vector2i(128, 128)

var grid: Dictionary[Vector2i, TileInfo] = {}
var layers: Array[TileMapLayer] = []

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("rotate_left") and event.is_released():
		rotate_map_and_camera(true)
	elif event.is_action("rotate_right") and event.is_released():
		rotate_map_and_camera(false)

func _ready() -> void:
	pass # Replace with function body.

# --- Cell Utility Functions ---

func set_cell(actual_tile: Vector2i, atlas: Vector2i, height: float) -> void:
	grid[actual_tile] = TileInfo.new(atlas, height)
	var local_tile = get_local_tile(actual_tile)
	layers[floor(height)].set_cell(local_tile, 0, atlas)

func get_cell(actual_tile: Vector2i) -> TileInfo:
	if (!grid.has(actual_tile)): return null
	return grid[actual_tile]

func replace_cell(actual_tile: Vector2i, atlas: Vector2i) -> void:
	assert(grid.has(actual_tile))
	var height = grid[actual_tile].height
	grid[actual_tile].atlas = atlas
	var local_tile = get_local_tile(actual_tile)
	layers[floor(height)].set_cell(local_tile, 0, atlas)

func get_cell_from_local(local_pos: Vector2) -> Vector2i:
	
	var helper = func (local_position: Vector2, height: int) -> Variant:
		var layer: TileMapLayer = layers[height]
		for i: int in range(33):
			var local_tile: Vector2i = layer.local_to_map(local_position - Vector2(0, i))
			var actual_tile: Vector2i = get_real_tile(local_tile)
			var tile_info: TileInfo = get_cell(actual_tile)
			if (tile_info and tile_info.height == height): return actual_tile
		return null
	
	for height: int in range(layers.size() - 1, -1, -1):
		var offset = Vector2(0, 32 * height)
		
		var actual_tile: Variant = helper.call(local_pos + offset, height)
		if (actual_tile == null): continue

		var tile_info: TileInfo = get_cell(actual_tile)
		if (tile_info != null and floor(tile_info.height) == height):
			return actual_tile
	var local_tile_backup = layers[0].local_to_map(local_pos)
	return get_real_tile(local_tile_backup)

func get_local_from_cell(actual_tile: Vector2i) -> Vector2:
	var tile_info: TileInfo = get_cell(actual_tile)
	var local_tile: Vector2i = get_local_tile(actual_tile)
	if (tile_info != null):
		return layers[tile_info.height].map_to_local(local_tile) - Vector2(0, 32 * tile_info.height)
	else:
		return layers[0].map_to_local(local_tile)

# --- Rotations and Local/Actual Conversions ---
 
func rotate_map(rotate_left: bool) -> void:
	for height: int in LAYERS:
		rotate_layer(height, rotate_left)
	
	current_rotation = get_next_rotation(rotate_left)
	print(current_rotation)

func rotate_layer(height: int, rotate_left: bool) -> void:
	var layer: TileMapLayer = layers[height]
	var used_cells: Array[Vector2i] = layer.get_used_cells()
	
	layer.clear()
	
	for cell: Vector2i in used_cells:
		var actual_pos: Vector2i = unrotate_tile(cell, current_rotation)
		
		var rotated_tile: Vector2i = rotate_tile(actual_pos, get_next_rotation(rotate_left))
		var tile_info = get_cell(actual_pos)
		if (tile_info == null): continue
		var atlas: Vector2i = tile_info.atlas
		layer.set_cell(rotated_tile, 0, atlas)

func get_next_rotation(rotate_left: bool) -> int:
	if (rotate_left):
		if (current_rotation == 0): return 3
		return (current_rotation - 1)
	else:
		return (current_rotation + 1) % 4
		

func get_real_tile(local_tile: Vector2i) -> Vector2i:
	return unrotate_tile(local_tile, current_rotation)

func get_local_tile(real_tile: Vector2i) -> Vector2i:
	return rotate_tile(real_tile, current_rotation)

func unrotate_tile(pos: Vector2i, rot: int) -> Vector2i:
	var rotated = pos
	for i in range(0, rot):
		rotated = Vector2i(
			rotated.y,
			-rotated.x
		)
	return rotated

func rotate_tile(pos: Vector2i, rot: int) -> Vector2i:
	var rotated = pos
	for i in range(0, rot):
		rotated = Vector2i(
			-rotated.y,
			rotated.x
		)
	return rotated

func rotate_map_and_camera(rotate_left: bool) -> void:
	var pos: Vector2 = PlayerCamera.get_instance().get_screen_center_position()
	var before_tile = get_cell_from_local(pos)
	
	rotate_map(rotate_left)
	
	var new_pos = get_local_from_cell(before_tile)
	PlayerCamera.get_instance().set_screen_with_center_position(new_pos)
