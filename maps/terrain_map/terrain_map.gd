class_name TerrainMap extends RotatableMap

static var singleton_instance: TerrainMap = null

static func get_instance() -> TerrainMap:
	assert(singleton_instance != null, "Terrain Map has not been instanced yet.")
	return singleton_instance

static var e: float = 2.71828 
var noise_seed: int = 100
var noise = FastNoiseLite.new()
var thread: Thread

func _input(event: InputEvent) -> void:
	var local_mouse_pos = get_local_mouse_position()
	var tile_on_mouse = get_cell_from_local(local_mouse_pos)
	var player_camera: PlayerCamera = PlayerCamera.get_instance()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			replace_cell(tile_on_mouse, Vector2i(2, 0))
	elif event.is_action("debug"):
		visible = !visible
	
	player_camera.set_mouse_coords_label(tile_on_mouse)
	
	var local_camera_pos: Vector2 = player_camera.get_screen_center_position()
	var tile_on_camera = get_cell_from_local(local_camera_pos)
	
	player_camera.set_camera_coords_label(tile_on_camera)

func _ready() -> void:
	var tileset: TileSet = create_tile_set()
	
	for i in range(LAYERS):
		var layer = TileMapLayer.new()
		layer.tile_set = tileset
		layer.z_index = 0
		layers.append(layer)
		layer.position = Vector2i(0, -32 * i)
		layer.y_sort_origin = 32 * i
		layer.y_sort_enabled = true
		#layer.modulate = Color((float(i) / LAYERS) + 0.15, (float(i) / LAYERS) + 0.15, (float(i) / LAYERS + 0.15), 1)
		add_child(layer)
	
	generate_map()
	#set_cell(Vector2i(0, 0), Vector2i(0, 0), 0)
	#set_cell(Vector2i(0, -1), Vector2i(0, 0), 1)
	#set_cell(Vector2i(-1, -1), Vector2i(0, 0), 1)
	#set_cell(Vector2i(0, -2), Vector2i(0, 0), 2)
	#set_cell(Vector2i(0, -3), Vector2i(0, 0), 3)
	assert(singleton_instance == null, "Terrain Map has been instanced twice.")
	singleton_instance = self
	
	thread = Thread.new()
	thread.start(create_cities.bind())

func create_cities() -> void:
	while(CityMap.singleton_instance == null):
		OS.delay_msec(10)
	CityMap.get_instance().generate_cities()

func create_tile_set() -> TileSet:
	var tileset: TileSet = TileSet.new()
	tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tileset.tile_size = Vector2i(64, 32)
	tileset.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	
	var source = TileSetAtlasSource.new()
	source.texture = load("res://assets/isometric.png")
	source.texture_region_size = Vector2i(64, 96)
	
	source.create_tile(Vector2i(0, 0))
	source.create_tile(Vector2i(1, 0))
	source.create_tile(Vector2i(2, 0))
	source.create_tile(Vector2i(3, 0))
	source.create_tile(Vector2i(4, 0))
	source.create_tile(Vector2i(0, 1))
	source.create_tile(Vector2i(1, 1))
	tileset.add_source(source)
	return tileset

func generate_map() -> void:
	# Higher value, bigger mountains
	const MOUNTAINNESS = 1.5
	# 1. Initialize Noise
	noise.seed = noise_seed if noise_seed != 0 else randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05
	
	# 2. Iterate through the grid
	@warning_ignore("integer_division")
	for x in range(-map_size.x / 2, map_size.x / 2):
		@warning_ignore("integer_division")
		for y in range(-map_size.y / 2, map_size.y / 2):
			# get_noise_2d returns a value between 0 and 2.0
			var noise_val = noise.get_noise_2d(x, y) + 1
			var f_val = noise.get_noise_2d(y, x) + 1
			
			# redistribute values for height
			var h_val = pow(noise_val, MOUNTAINNESS)
			
			# 3. Determine terrain based on thresholds
			place_terrain(x, y, h_val, f_val)
	#generate_rivers()

func place_terrain(x: int, y: int, h_val: float, f_val: float) -> void:
	# TODO: MAKE SURE THAT HEIGHT IS abs(height - MAX(HEIGHT_OF_SURROUNDING_TILES)) <= 1
	
	var height: float = (h_val) * 2.0
	var forested: bool = f_val > 1.0
	var x_offset: int = 2 if forested else 0
	
	if (height <= 1):
		set_cell(Vector2i(x, y), Vector2i(4, 0), 0)
		return
	
	# Logic for mapping noise values to terrain
	height = min(round_to_step(height, 0.5), LAYERS - 1 + 0.5)
	
	if (height > floor(height)):
		set_cell(Vector2i(x, y), Vector2i(0 + x_offset, 0), min(floor(height), LAYERS - 1))
	else:
		set_cell(Vector2i(x, y), Vector2i(1 + x_offset, 0), min(floor(height), LAYERS - 1))

func round_to_step(value: float, step: float) -> float:
	if step == 0.0:
		return value
	return round(value / step) * step

func generate_rivers() -> void:
	var path: Array[Vector2i] = a_star(Vector2i(4, -10), Vector2i(30, 40))
	for tile: Vector2i in path:
		replace_cell(tile, Vector2i(4, 0))

# --- Pathfinding ---

func is_tile_traversable(actual_tile: Vector2i) -> bool:
	var cell: Variant = get_cell(actual_tile)
	if (cell == null): return false
	var atlas: Vector2i = get_cell(actual_tile).atlas
	return atlas != Vector2i(-1, -1)

func create_route_from_tile_to_prev(start: Vector2i, destination: Vector2i, tile_to_prev: Dictionary) -> Array[Vector2i]:
	var current: Vector2i = destination
	var route: Array[Vector2i] = []
	while current != start:
		route.push_front(current)
		current = tile_to_prev[current]
	return route

func a_star(start: Vector2i, destination: Vector2i) -> Array[Vector2i]:
	
	# Can't reach dest
	if (!is_tile_traversable(destination)):
		return []
	
	var current: Vector2i
	var queue: priority_queue = priority_queue.new()
	var tile_to_prev: Dictionary = {}
	var visited: Dictionary = {}
	var found: bool = false
	queue.insert_element(start, 0)
	visited[start] = 0
	const MAX_TRIES: int = 100000
	var tries: int = 0
	
	var get_h_cost = func(_pos: Vector2i) -> float:
		return 0 # TODO: FIX HEURISTIC
	
	var get_tile_cost = func(s_tile: Vector2i, e_tile: Vector2i) -> float:
		var h1 = get_cell(s_tile).height
		var h2 = get_cell(e_tile).height
		
		return pow(e, h2 - h1)
	
	while !queue.is_empty():
		tries += 1
		if (tries >= MAX_TRIES):
			print("TOO")
			break
		current = queue.pop_back()
		if current == destination:
			found = true
			break
		for tile: Vector2i in layers[0].get_surrounding_cells(current):
			if (!is_tile_traversable(tile)): continue
			
			var base_cost: float = visited[current] + get_tile_cost.call(current, tile)
			var h_cost: float = get_h_cost.call(tile)
			if (!visited.has(tile) or visited[tile] > base_cost):
				queue.insert_element(tile, base_cost + h_cost)
				visited[tile] = base_cost
				tile_to_prev[tile] = current
	if found:
		return create_route_from_tile_to_prev(start, destination, tile_to_prev)
	else:
		return []
