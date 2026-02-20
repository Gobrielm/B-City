class_name RotatableMap extends Node2D

var current_rotation: int = 0
const LAYERS: int = 10
const map_size: Vector2i = Vector2i(128, 128)

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

func set_cell(actual_tile: RealTile, tile_info: TileInfo) -> void:
	grid[actual_tile.hash()] = tile_info
	var local_tile: LocalTile = get_local_tile(actual_tile)
	layers[tile_info.height].set_cell(local_tile.tile, 0, tile_info.atlas)

func get_cell(actual_tile: RealTile) -> TileInfo:
	if (!grid.has(actual_tile.hash())): return null
	return grid[actual_tile.hash()]

func replace_cell(actual_tile: RealTile, atlas: Vector2i) -> void:
	assert(grid.has(actual_tile))
	var height: int = grid[actual_tile.hash()].height
	grid[actual_tile.hash()].atlas = atlas
	var local_tile: LocalTile = get_local_tile(actual_tile)
	layers[height].set_cell(local_tile.tile, 0, atlas)

func erase_cell(actual_tile: RealTile) -> void:
	assert(grid.has(actual_tile.hash()))
	var height: int = grid[actual_tile.hash()].height
	grid.erase(actual_tile.hash())
	var local_tile: LocalTile = get_local_tile(actual_tile)
	layers[height].erase_cell(local_tile.tile)

func get_used_cells() -> Array[RealTile]:
	var toReturn: Array[RealTile] = []
	for layer: TileMapLayer in layers:
		for cell: Vector2i in layer.get_used_cells():
			toReturn.push_back(get_real_tile(LocalTile.new(cell)))
	return toReturn

func get_used_cells_by_id(atlas: Vector2i) -> Array[RealTile]:
	var toReturn: Array[RealTile] = []
	for layer: TileMapLayer in layers:
		for cell: Vector2i in layer.get_used_cells_by_id(0, atlas):
			toReturn.push_back(get_real_tile(LocalTile.new(cell)))
	return toReturn

func get_used_cells_by_multiple_ids(atlases: Array[Vector2i]) -> Array[RealTile]:
	var toReturn: Array[RealTile] = []
	for layer: TileMapLayer in layers:
		for atlas: Vector2i in atlases:
			for cell: Vector2i in layer.get_used_cells_by_id(0, atlas):
				toReturn.push_back(get_real_tile(LocalTile.new(cell)))
	return toReturn

func get_surrounding_cells(tile: Vector2i) -> Array[Vector2i]:
	return layers[0].get_surrounding_cells(tile)

# --- Pathfinding ---
func bfs(start: RealTile, destination: RealTile, is_traversable: Callable = func (_tile: RealTile) -> bool: return true) -> Array[RealTile]:
	var current: RealTile
	var queue: Array[RealTile] = [start]
	var tile_to_prev: Dictionary[RealTile, RealTile] = {}
	var visited: Dictionary[RealTile, int] = {}
	var found: bool = false
	visited[start] = 0
	
	while !queue.is_empty():
		current = queue.pop_front()
		if current == destination:
			found = true
			break
		for real: Vector2i in layers[0].get_surrounding_cells(current.tile):
			var real_tile: RealTile = RealTile.new(real)
			if (!visited.has(real_tile) and is_traversable.call(real_tile)):
				queue.push_back(real_tile)
				visited[real_tile] = 0
				tile_to_prev[real_tile] = current
	if found:
		return create_route_from_tile_to_prev(start, destination, tile_to_prev)
	else:
		return []


func create_route_from_tile_to_prev(start: RealTile, destination: RealTile, tile_to_prev: Dictionary[RealTile, RealTile]) -> Array[RealTile]:
	var current: RealTile = destination
	var route: Array[RealTile] = []
	while current != start:
		route.push_front(current)
		current = tile_to_prev[current]
	return route

# --- Rotations and Local/Actual Conversions ---

func get_cell_from_local(local_pos: Vector2) -> RealTile:
	var helper: Callable = func (local_position: Vector2, height: int) -> RealTile:
		var layer: TileMapLayer = layers[height]
		for i: int in range(33):
			var local_tile: LocalTile = LocalTile.new(layer.local_to_map(local_position - Vector2(0, i)))
			var actual_tile: RealTile = get_real_tile(local_tile)
			var tile_info: TileInfo = get_cell(actual_tile)
			if (tile_info and tile_info.height == height): return actual_tile
		return null
	
	for height: int in range(layers.size() - 1, -1, -1):
		var offset: Vector2 = Vector2(0, 32 * height)
		
		var actual_tile: RealTile = helper.call(local_pos + offset, height)
		if (actual_tile == null): continue
		
		var tile_info: TileInfo = get_cell(actual_tile)
		if (tile_info != null and tile_info.height == height):
			return actual_tile
	var local_tile_backup: LocalTile = LocalTile.new(layers[0].local_to_map(local_pos))
	return get_real_tile(local_tile_backup)

func get_local_from_cell(actual_tile: RealTile) -> Vector2:
	var tile_info: TileInfo = get_cell(actual_tile)
	var local_tile: LocalTile = get_local_tile(actual_tile)
	if (tile_info != null):
		return layers[tile_info.height].map_to_local(local_tile.tile) - Vector2(0, 32 * tile_info.height)
	else:
		return layers[0].map_to_local(local_tile.tile)
 
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
		var actual_pos: RealTile = RealTile.new(unrotate_tile(cell, current_rotation))
		
		var rotated_tile: Vector2i = rotate_tile(actual_pos.tile, get_next_rotation(rotate_left))
		var tile_info: TileInfo = get_cell(actual_pos)
		if (tile_info == null): continue
		var atlas: Vector2i = tile_info.atlas
		layer.set_cell(rotated_tile, 0, atlas)

func get_next_rotation(rotate_left: bool) -> int:
	if (rotate_left):
		if (current_rotation == 0): return 3
		return (current_rotation - 1)
	else:
		return (current_rotation + 1) % 4
		

func get_real_tile(local_tile: LocalTile) -> RealTile:
	return RealTile.new(unrotate_tile(local_tile.tile, current_rotation))

func get_local_tile(real_tile: RealTile) -> LocalTile:
	return LocalTile.new(rotate_tile(real_tile.tile, current_rotation))

func unrotate_tile(pos: Vector2i, rot: int) -> Vector2i:
	var rotated: Vector2i = pos
	for i: int in range(0, rot):
		rotated = Vector2i(
			rotated.y,
			-rotated.x
		)
	return rotated

func rotate_tile(pos: Vector2i, rot: int) -> Vector2i:
	var rotated: Vector2i = pos
	for i: int in range(0, rot):
		rotated = Vector2i(
			-rotated.y,
			rotated.x
		)
	return rotated

func rotate_map_and_camera(rotate_left: bool) -> void:
	var pos: Vector2 = PlayerCamera.get_instance().get_screen_center_position()
	var before_tile: RealTile = get_cell_from_local(pos)
	
	rotate_map(rotate_left)
	
	move_camera_to_tile(before_tile)

func move_camera_to_tile(tile: RealTile) -> void:
	var new_pos: Vector2i = get_local_from_cell(tile)
	PlayerCamera.get_instance().set_screen_with_center_position(new_pos)
