class_name CityMap extends RotatableMap

var people: Dictionary[int, Person] = {}
var people_to_remove: Array[int] = []

static var singleton_instance: CityMap = null

static func get_instance() -> CityMap:
	assert(singleton_instance != null, "City Map has not been instanced yet.")
	return singleton_instance

func _process(_delta: float) -> void:
	clean_people()
	spawn_person()

func _input(event: InputEvent) -> void:
	if (event.is_action_released("debug")):
		spawn_person()

func _ready() -> void:
	assert(singleton_instance == null, "City Map has been instanced twice.")
	
	var tileset: TileSet = create_tile_set()
	
	for i: int in range(LAYERS):
		var layer: TileMapLayer = TileMapLayer.new()
		layer.tile_set = tileset
		layer.z_index = 0
		layers.append(layer)
		layer.position = Vector2i(0, -32 * i)
		layer.y_sort_origin = 32 * i
		layer.y_sort_enabled = true
		#layer.modulate = Color((float(i) / LAYERS) + 0.15, (float(i) / LAYERS) + 0.15, (float(i) / LAYERS + 0.15), 1)
		add_child(layer)
	
	singleton_instance = self

func rotate_map(rotate_left: bool) -> void:
	super.rotate_map(rotate_left)
	
	for person: Person in people.values():
		var current_pos: RealTile = person.get_current_target()
		if (current_pos == null): continue
		person.position = get_local_from_cell(current_pos)

func append_person_to_remove(person_id: int) -> void:
	people_to_remove.append(person_id)

func clean_people() -> void:
	for person_id: int in people_to_remove:
		people[person_id].queue_free()
		people.erase(person_id)
	people_to_remove.clear()

func create_tile_set() -> TileSet:
	var tileset: TileSet = TileSet.new()
	tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tileset.tile_size = Vector2i(64, 32)
	tileset.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = load("res://assets/city_isometric.png")
	source.texture_region_size = Vector2i(64, 96)
	
	source.create_tile(Vector2i(0, 0))
	source.create_tile(Vector2i(1, 0))
	source.create_tile(Vector2i(2, 0))
	source.create_tile(Vector2i(3, 0))
	
	source.create_tile(Vector2i(0, 1))
	source.create_tile(Vector2i(1, 1))
	tileset.add_source(source)
	return tileset

# --- City Generation ---

func generate_cities() -> void:
	while TerrainMap.singleton_instance == null:
		OS.delay_msec(10)
	var locations: Array[RealTile] = []
	var tries: int = 0
	
	while locations.size() < 10:
		tries += 1
		if (tries > 1000):
			break
		
		var check_validity: Callable = func (rand_location: RealTile) -> bool:
			for location: RealTile in locations:
				if (location.distance_to(rand_location) < 30):
					return false
			return true
		
		@warning_ignore("integer_division")
		var rand_x: int = randi_range(-map_size.x / 2 + 1, map_size.x / 2 - 1)
		@warning_ignore("integer_division")
		var rand_y: int = randi_range(-map_size.y / 2 + 1, map_size.y / 2 - 1)
		var rand_tile: RealTile = RealTile.new(Vector2i(rand_x, rand_y))
		if (check_validity.call(rand_tile)):
			locations.push_front(rand_tile)
			break
		
	for location: RealTile in locations:
		generate_city(location)

func generate_city(center: RealTile) -> void:
	place_road(center)
	var directions: Array[Vector2i] = [
		Vector2i(0, 1),
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(-1, 0)
	]
	
	for direction: Vector2i in directions:
		if randi() % 3 != 0:
			generate_road(center.add_vector2i(direction), direction, 0)

func generate_road(tile: RealTile, direction: Vector2i, depth: int) -> void:
	if depth > 10 or randi() % 20 == 0:
		return

	var terrain_map: TerrainMap = TerrainMap.get_instance()
	var tile_info: TileInfo = terrain_map.get_cell(tile)
	if tile_info == null or tile_info.is_water():
		return
	
	if get_cell(tile) != null:
		if !(is_road(tile)):
			erase_cell(tile)
	
	place_road(tile)

	# Place buildings alongside the road
	if direction.x == 0:
		place_city_tile(tile.add_vector2i(Vector2i(1, 0)))
		place_city_tile(tile.add_vector2i(Vector2i(-1, 0)))
	else:
		place_city_tile(tile.add_vector2i(Vector2i(0, 1)))
		place_city_tile(tile.add_vector2i(Vector2i(0, -1)))

	# Continue straight
	generate_road(tile.add_vector2i(direction), direction, depth + 1)

	# Chance to branch
	if randi() % 8 == 0:
		var perpendiculars: Array[Vector2i] = get_perpendicular_dirs(direction)
		var branch_dir: Vector2i = perpendiculars[randi() % perpendiculars.size()]
		generate_road(tile.add_vector2i(branch_dir), branch_dir, depth + randi_range(-1, 3))

func place_road(location: RealTile) -> void:
	var terrain_map: TerrainMap = TerrainMap.get_instance()
	var tile_info: TileInfo = terrain_map.get_cell(location)
	if (tile_info == null): return
	var x_offset: int = 0
	if (tile_info.is_half_tile()): x_offset = 1
	set_cell(location, TileInfo.new(Vector2i(0 + x_offset, 1), tile_info.height))

func place_city_tile(location: RealTile) -> void:
	var terrain_map: TerrainMap = TerrainMap.get_instance()
	var tile_info: TileInfo = terrain_map.get_cell(location)
	if (tile_info == null or get_cell(location) != null): return
	var x_offset: int = 0 if (randi() % 3 == 0) else 2
	if (tile_info.is_half_tile()): x_offset = 1
	set_cell(location, TileInfo.new(Vector2i(0 + x_offset, 0), tile_info.height))

func is_road(real_tile: RealTile) -> bool:
	var tile_info: TileInfo = get_cell(real_tile)
	if (tile_info == null): return false
	var atlas: Vector2i = tile_info.atlas
	return atlas == Vector2i(0, 1) or atlas == Vector2i(1, 1)

func get_perpendicular_dirs(dir: Vector2i) -> Array[Vector2i]:
	if dir.x == 0:
		return [Vector2i(1, 0), Vector2i(-1, 0)]
	else:
		return [Vector2i(0, 1), Vector2i(0, -1)]

# --- People ---

func spawn_person() -> void:
	var cells: Array[RealTile] = get_used_cells_by_multiple_ids([Vector2i(0, 1), Vector2i(1, 1)])
	var cell: RealTile = cells.pick_random()
	var person_scene: PackedScene = load("res://transport_objects/person.tscn")
	var person: Person = person_scene.instantiate()
	person.position = get_local_from_cell(cell)
	add_child(person)
	person.set_route(create_route_for_person(cell))
	person.z_index = 0
	person.apply_scale(Vector2(2, 2))
	#person.apply_scale(Vector2(20, 20))
	people[person.get_instance_id()] = person
	#person.set_random_offset(Vector2(randi_range(0, 16), randi_range(0, 16)))
	#move_camera_to_tile(cell)
	
func get_tiles_connected_by_road(real_start: RealTile) -> Array[RealTile]:
	var queue: Array[RealTile] = [real_start]
	var visited: Dictionary[Vector2i, bool] = {}
	var connected: Array[RealTile] = []

	if not is_road(real_start):
		return []

	visited[real_start.hash()] = true

	while not queue.is_empty():
		var current: RealTile = queue.pop_front()

		for t: Vector2i in get_surrounding_cells(current.tile):
			var tile: RealTile = RealTile.new(t)
			if visited.has(tile.hash()) or not is_road(tile):
				continue
			connected.push_back(tile)
			visited[tile.hash()] = true
			queue.push_back(tile)

	return connected

func create_route_for_person(starting_pos: RealTile) -> Array[RealTile]:
	var end_pos: RealTile = get_tiles_connected_by_road(starting_pos).pick_random()
	if end_pos == null:
		return []
	var route: Array[RealTile] = bfs(starting_pos, end_pos, is_road)
	
	return route
