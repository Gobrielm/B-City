class_name CityMap extends RotatableMap

const LAYERS: int = 11

var people: Dictionary[int, Person] = {}
var people_to_remove: Array[int] = []
var houses: Dictionary[Vector2i, House] = {}
var shops: Dictionary[Vector2i, Shop] = {}

static var singleton_instance: CityMap = null

static func get_instance() -> CityMap:
	assert(singleton_instance != null, "City Map has not been instanced yet.")
	return singleton_instance

func _process(_delta: float) -> void:
	if singleton_instance == null:
		return
	#clean_people()
	#process_map_objects()
	#spawn_person()

func _input(event: InputEvent) -> void:
	if event.is_action_released("debug"):
		for layer: TileMapLayer in layers:
			layer.visible = true
	elif event.is_action_pressed("debug"):
		for layer: TileMapLayer in layers:
			layer.visible = false
	#elif event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			#var tile_on_mouse: RealTile = get_cell_from_local(get_local_mouse_position())
			#spawn_person(tile_on_mouse)

# Move roads to seperate tilemap?

func _ready() -> void:
	assert(singleton_instance == null, "City Map has been instanced twice.")
	
	var tileset: TileSet = create_tile_set()
	
	for i: int in range(LAYERS + 1):
		var layer: TileMapLayer = TileMapLayer.new()
		layer.tile_set = tileset
		layer.z_index = 0
		layers.append(layer)
		layer.position = Vector2i(0, -16 * i)
		layer.y_sort_origin = 16 * i
		layer.y_sort_enabled = true
		#layer.modulate = Color((float(i) / LAYERS) + 0.15, (float(i) / LAYERS) + 0.15, (float(i) / LAYERS + 0.15), 1)
		add_child(layer)
	
	singleton_instance = self

func rotate_map(rotate_left: bool) -> void:
	super.rotate_map(rotate_left)
	
	for person: Person in people.values():
		var current_pos: RealTile = person.get_current_target()
		if (current_pos == null): continue
		person.set_pos(current_pos)

func append_person_to_remove(person_id: int) -> void:
	people_to_remove.append(person_id)

func process_map_objects() -> void:
	for pos: Vector2i in houses:
		houses[pos].process()
	
	for pos: Vector2i in shops:
		shops[pos].process()

func clean_people() -> void:
	for person_id: int in people_to_remove:
		people[person_id].household.return_person()
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
	source.margins = Vector2i(0, 16)
	source.texture_region_size = Vector2i(64, 64)
	
	source.create_tile(Vector2i(0, 0))
	source.create_tile(Vector2i(1, 0))
	
	source.create_tile(Vector2i(0, 1))
	tileset.add_source(source)
	return tileset

# --- City Generation ---

func generate_cities() -> void:
	@warning_ignore("integer_division")
	var rand_x: int = randi_range(-map_size.x / 2 + 1, map_size.x / 2 - 1)
	@warning_ignore("integer_division")
	var rand_y: int = randi_range(-map_size.y / 2 + 1, map_size.y / 2 - 1)
	var rand_tile: RealTile = RealTile.new(Vector2i(rand_x, rand_y))
	generate_city(rand_tile, 20)
	#var locations: Array[RealTile] = []
	#var tries: int = 0
	
	#while locations.size() < 10:
		#tries += 1
		#if (tries > 1000):
			#break
		#
		#var check_validity: Callable = func (rand_location: RealTile) -> bool:
			#for location: RealTile in locations:
				#if (location.distance_to(rand_location) < 30):
					#return false
			#return true
		#
		#@warning_ignore("integer_division")
		#var rand_x: int = randi_range(-map_size.x / 2 + 1, map_size.x / 2 - 1)
		#@warning_ignore("integer_division")
		#var rand_y: int = randi_range(-map_size.y / 2 + 1, map_size.y / 2 - 1)
		#var rand_tile: RealTile = RealTile.new(Vector2i(rand_x, rand_y))
		#if (check_validity.call(rand_tile)):
			#locations.push_front(rand_tile)
		#
	#for location: RealTile in locations:
		#generate_city(location, 10)

func generate_city(center: RealTile, size: int) -> void:
	place_road(center)
	var directions: Array[Vector2i] = [
		Vector2i(0, 1),
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(-1, 0)
	]
	
	for direction: Vector2i in directions:
		if randi() % 4 != 0:
			generate_road(center.add_vector2i(direction), direction, size, false)
	
	add_road_grids(4)
	spawn_buildings()

func generate_road(tile: RealTile, direction: Vector2i, size: int, can_branch: bool) -> void:
	if size <= 0 or randi() % (size * 2) == 0:
		return

	var terrain_map: TerrainMap = TerrainMap.get_instance()
	var tile_info: TileInfo = terrain_map.get_cell(tile)
	if tile_info == null or tile_info.is_water():
		return
	
	if get_cell(tile) != null:
		if !(is_road(tile)):
			erase_cell(tile)
	
	place_road(tile)

	var branched: bool = false
	# Chance to branch
	if can_branch and randi() % 8 == 0:
		branched = true
		var perpendiculars: Array[Vector2i] = get_perpendicular_dirs(direction)
		var branch_dir: Vector2i = perpendiculars[randi() % perpendiculars.size()]
		generate_road(tile.add_vector2i(branch_dir), branch_dir, size - randi_range(0, 3), false)
	
	# Continue straight
	generate_road(tile.add_vector2i(direction), direction, size - 1, !branched)

func place_road(location: RealTile) -> void:
	var terrain_map: TerrainMap = TerrainMap.get_instance()
	var tile_info: TileInfo = terrain_map.get_cell(location)
	if (tile_info == null): return
	set_cell(location, TileInfo.new(Vector2i(0, 1), tile_info.height))

func place_building(location: RealTile) -> void:
	if randi_range(0, 3) == 0:
		place_shop_tile(location)
	else:
		place_city_tile(location)

func place_city_tile(location: RealTile) -> void:
	var terrain_map: TerrainMap = TerrainMap.get_instance()
	var tile_info: TileInfo = terrain_map.get_cell(location)
	if (tile_info == null): return
	set_cell(location, TileInfo.new(Vector2i(0, 0), tile_info.height + 1))
	houses[location.hash()] = House.new(location, 2)

func place_shop_tile(location: RealTile) -> void:
	var terrain_map: TerrainMap = TerrainMap.get_instance()
	var tile_info: TileInfo = terrain_map.get_cell(location)
	if (tile_info == null): return
	set_cell(location, TileInfo.new(Vector2i(1, 0), tile_info.height + 1))
	shops[location.hash()] = Shop.new(location)

func is_road(real_tile: RealTile) -> bool:
	var tile_info: TileInfo = get_cell(real_tile)
	if (tile_info == null): return false
	var atlas: Vector2i = tile_info.atlas
	return atlas == Vector2i(0, 1)

func is_road_vertex(tile: RealTile) -> bool:
	var cnt: int = 0
	for cell: Vector2i in get_surrounding_cells(tile.tile):
		if is_road(RealTile.new(cell)):
			cnt += 1
	return cnt > 2

func is_shop(real_tile: RealTile) -> bool:
	var tile_info: TileInfo = get_cell(real_tile)
	if (tile_info == null): return false
	var atlas: Vector2i = tile_info.atlas
	return atlas == Vector2i(1, 0)

func is_building(real_tile: RealTile) -> bool:
	var tile_info: TileInfo = get_cell(real_tile)
	if (tile_info == null): return false
	var atlas: Vector2i = tile_info.atlas
	return atlas == Vector2i(1, 0) or atlas == Vector2i(0, 0)

func get_perpendicular_dirs(dir: Vector2i) -> Array[Vector2i]:
	if dir.x == 0:
		return [Vector2i(1, 0), Vector2i(-1, 0)]
	else:
		return [Vector2i(0, 1), Vector2i(0, -1)]

func add_road_grids(block_size: int) -> void:
	
	var attempt_to_build_block: Callable = func (road_vertex: RealTile) -> void:
		const chance_to_fail: int = 25
		var edges_valid: Dictionary[Vector2i, bool] = {}
		var edge_dirs: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
		# Gets valid edges
		for dir: Vector2i in edge_dirs:
			for i: int in range(1, block_size):
				if !is_road(road_vertex.add_vector2i(dir * i)):
					edges_valid[dir] = false
					break
			if !edges_valid.has(dir):
				edges_valid[dir] = true
		
		for ind: int in edge_dirs.size() - 1:
			var dir: Vector2i = edge_dirs[ind]
			var next_dir: Vector2i = edge_dirs[ind + 1]
			
			if !edges_valid[dir] or !edges_valid[next_dir]:
				continue
			if randi_range(0, 100) < chance_to_fail:
				continue
			
			for i: int in range(1, block_size):
				place_road(road_vertex.add_vector2i(dir * i + next_dir * block_size))
				place_road(road_vertex.add_vector2i(dir * block_size + next_dir * i))
			place_road(road_vertex.add_vector2i(dir * block_size + next_dir * block_size))
	
	var checked: Dictionary[Vector2i, bool] = {}

	# Iterate over every existing road tile as potential block origin
	for road_tile: RealTile in get_used_cells_by_id(Vector2i(0, 1)):
		if checked.has(road_tile.hash()) or !is_road_vertex(road_tile):
			continue
		checked[road_tile.hash()] = true
		
		attempt_to_build_block.call(road_tile)


func spawn_buildings() -> void:
	var spawn_building: Callable = func (tile: RealTile) -> void:
		var corners: Array[Vector2i] = get_corner_tiles(tile.tile)
		var road_corners: int = 0
		for corner: Vector2i in corners:
			if is_road(RealTile.new(corner)): 
				road_corners += 1
		
		if get_cell(tile) == null and road_corners >= 1:
			place_building(tile)
	
	for tile: RealTile in get_used_cells_by_id(Vector2i(0, 1)):
		for n_tile: Vector2i in get_surrounding_cells(tile.tile):
			var neighbor: RealTile = RealTile.new(n_tile)
			spawn_building.call(neighbor)

# --- People ---

func spawn_person(tile_to_spawn_at: RealTile) -> void:
	var person_scene: PackedScene = load("res://transport_objects/person.tscn")
	var person: Person = person_scene.instantiate()
	person.household = houses[tile_to_spawn_at.tile]
	
	person.set_route(create_route_for_person(tile_to_spawn_at))
	
	add_child(person)
	person.z_index = 0
	person.apply_scale(Vector2(2, 2))
	people[person.get_instance_id()] = person
	person.set_random_offset(Vector2(randi_range(0, 16), randi_range(0, 16)))
	person.set_pos(tile_to_spawn_at)

func create_route_for_person(starting_pos: RealTile) -> Array[RealTile]:
	var route: Array[RealTile] = bfs_to_goal(starting_pos, is_road, is_shop)
	route.push_front(starting_pos)
	
	return route

func get_tiles_connected_by_road(real_start: RealTile) -> Array[RealTile]:
	var queue: Array[RealTile] = [real_start]
	var visited: Dictionary[Vector2i, bool] = {}
	var connected: Array[RealTile] = [real_start]

	assert(is_road(real_start))

	visited[real_start.hash()] = true

	while !queue.is_empty():
		var current: RealTile = queue.pop_front()

		for t: Vector2i in get_surrounding_cells(current.tile):
			var tile: RealTile = RealTile.new(t)
			if visited.has(tile.hash()) or not is_road(tile):
				continue
			connected.push_back(tile)
			visited[tile.hash()] = true
			queue.push_back(tile)
	
	return connected
