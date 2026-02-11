extends Node2D

const LAYERS: int = 10
var noise_seed: int = 100
var noise = FastNoiseLite.new()
var map_size = Vector2i(128, 128)

var current_rotation: int = 0
var rotation_90: Transform2D = Transform2D(1.57079632679, Vector2(0, 0))

class TileInfo:
	var atlas: Vector2i
	var height: int
	
	func _init(p_atlas: Vector2i = Vector2i(0, 0), p_height: int = -1) -> void:
		atlas = p_atlas
		height = p_height

var terrain_grid: Dictionary[Vector2i, TileInfo] = {}
var terrain_layers: Array[TileMapLayer] = []

func _input(event: InputEvent) -> void:
	var local_mouse_pos = get_local_mouse_position()
	var tile_on_mouse = get_cell_from_local(local_mouse_pos)
	var player_camera: PlayerCamera = PlayerCamera.get_instance()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			replace_cell(tile_on_mouse, Vector2i(2, 0))
	elif event.is_action("rotate_map") and event.is_released():
		rotate_map_and_camera()
	
	player_camera.set_mouse_coords_label(tile_on_mouse)
	
	var local_camera_pos: Vector2 = player_camera.get_screen_center_position()
	var tile_on_camera = get_cell_from_local(local_camera_pos)
	
	player_camera.set_camera_coords_label(tile_on_camera)

func _ready() -> void:
	var tileset: TileSet = TileSet.new()
	tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tileset.tile_size = Vector2i(64, 32)
	tileset.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	
	var source = TileSetAtlasSource.new()
	source.texture = load("res://assets/isometric.png")
	source.texture_region_size = Vector2i(64, 96)
	
	source.create_tile(Vector2i(0, 0))
	source.create_tile(Vector2i(2, 0))
	source.create_tile(Vector2i(1, 0))
	tileset.add_source(source)
	
	for i in range(0, LAYERS):
		var layer = TileMapLayer.new()
		layer.tile_set = tileset
		layer.z_index = 0
		terrain_layers.append(layer)
		layer.position = Vector2i(0, -32 * i)
		layer.y_sort_origin = 32 * i
		layer.y_sort_enabled = true
		#layer.modulate = Color((i / 10.0), (i / 10.0), (i / 10.0), 1)
		add_child(layer)
	
	generate_map()
	#set_cell(Vector2i(0, 0), Vector2i(0, 0), 0)
	#set_cell(Vector2i(0, -1), Vector2i(0, 0), 1)
	#set_cell(Vector2i(-1, -1), Vector2i(0, 0), 1)
	#set_cell(Vector2i(0, -2), Vector2i(0, 0), 2)
	#set_cell(Vector2i(0, -3), Vector2i(0, 0), 3)

func generate_map() -> void:
	# Higher value, bigger mountains
	const MOUNTAINNESS = 1.5
	# 1. Initialize Noise
	noise.seed = noise_seed if noise_seed != 0 else randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05
	
	# 2. Iterate through the grid
	for x in range(-map_size.x / 2, map_size.x / 2):
		for y in range(-map_size.y / 2, map_size.y / 2):
			# get_noise_2d returns a value between 0 and 2.0
			var noise_val = noise.get_noise_2d(x, y) + 1
			
			# redistribute values for height
			var h_val = pow(noise_val, MOUNTAINNESS)
			
			# 3. Determine terrain based on thresholds
			place_terrain(x, y, h_val)

func set_cell(actual_tile: Vector2i, atlas: Vector2i, height: int) -> void:
	terrain_grid[actual_tile] = TileInfo.new(atlas, height)
	var local_tile = get_local_tile(actual_tile)
	terrain_layers[height].set_cell(local_tile, 0, atlas)

func get_cell(actual_tile: Vector2i) -> TileInfo:
	if (!terrain_grid.has(actual_tile)): return null
	return terrain_grid[actual_tile]

func replace_cell(actual_tile: Vector2i, atlas: Vector2i) -> void:
	assert(terrain_grid.has(actual_tile))
	var height = terrain_grid[actual_tile].height
	terrain_grid[actual_tile].atlas = atlas
	var local_tile = get_local_tile(actual_tile)
	terrain_layers[height].set_cell(local_tile, 0, atlas)

func place_terrain(x: int, y: int, h_val: float) -> void:
	# TODO: MAKE SURE THAT HEIGHT IS abs(height - MAX(HEIGHT_OF_SURROUNDING_TILES)) <= 1
	
	var height: float = (h_val) * 5.0
	
	# Logic for mapping noise values to terrain
	set_cell(Vector2i(x, y), Vector2i(0, 0), min(floor(height), LAYERS - 1))

func get_cell_from_local(local_pos: Vector2) -> Vector2i:
	
	var helper = func (local_position: Vector2, height: int) -> Variant:
		var layer: TileMapLayer = terrain_layers[height]
		for i: int in range(33):
			var local_tile: Vector2i = layer.local_to_map(local_position - Vector2(0, i))
			var actual_tile: Vector2i = get_real_tile(local_tile)
			var tile_info: TileInfo = get_cell(actual_tile)
			if (tile_info and tile_info.height == height): return actual_tile
		return null
		
	
	for height: int in range(terrain_layers.size() - 1, -1, -1):
		var offset = Vector2(0, 32 * height)
		
		var actual_tile: Variant = helper.call(local_pos + offset, height)
		if (actual_tile == null): continue

		var tile_info: TileInfo = get_cell(actual_tile)
		if (tile_info != null and tile_info.height == height):
			return actual_tile
	var local_tile_backup = terrain_layers[0].local_to_map(local_pos)
	return get_real_tile(local_tile_backup)



func get_local_from_cell(actual_tile: Vector2i) -> Vector2:
	var tile_info: TileInfo = get_cell(actual_tile)
	var local_tile: Vector2i = get_local_tile(actual_tile)
	if (tile_info != null):
		return terrain_layers[tile_info.height].map_to_local(local_tile) - Vector2(0, 32 * tile_info.height)
	else:
		return terrain_layers[0].map_to_local(local_tile)

func rotate_map() -> void:
	for height in LAYERS:
		rotate_layer(height)
	
	current_rotation = (current_rotation + 1) % 4
	print(current_rotation)

func rotate_layer(height: int) -> void:
	var layer: TileMapLayer = terrain_layers[height]
	var used_cells: Array[Vector2i] = layer.get_used_cells()
	
	layer.clear()
	
	for cell: Vector2i in used_cells:
		var actual_pos: Vector2i = unrotate_tile(cell, current_rotation)
		
		var rotated_tile: Vector2i = rotate_tile(actual_pos, (current_rotation + 1) % 4)
		var tile_info = get_cell(actual_pos)
		if (tile_info == null): continue
		var atlas: Vector2i = tile_info.atlas
		layer.set_cell(rotated_tile, 0, atlas)

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

func rotate_map_and_camera() -> void:
	var pos: Vector2 = PlayerCamera.get_instance().get_screen_center_position()
	var before_tile = get_cell_from_local(pos)
	
	rotate_map()
	
	var new_pos = get_local_from_cell(before_tile)
	PlayerCamera.get_instance().set_screen_with_center_position(new_pos)

#func rotate_map_and_camera() -> void:
	#var pos: Vector2 = PlayerCamera.get_instance().position
	#var local_tile_backup = terrain_layers[0].local_to_map(pos)
	#var tile_before: Vector2i = get_real_tile(local_tile_backup)
	#
	#rotate_map()
	#
	#var new_pos: Vector2 = terrain_layers[0].map_to_local(get_local_tile(tile_before))
	#PlayerCamera.get_instance().position = (new_pos)
	
