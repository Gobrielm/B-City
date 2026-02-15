class_name CityMap extends RotatableMap

static var singleton_instance: CityMap = null

static func get_instance() -> CityMap:
	assert(singleton_instance != null, "City Map has not been instanced yet.")
	return singleton_instance

func _ready() -> void:
	assert(singleton_instance == null, "City Map has been instanced twice.")
	
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
	
	singleton_instance = self

func _input(event: InputEvent) -> void:
	pass

func create_tile_set() -> TileSet:
	var tileset: TileSet = TileSet.new()
	tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tileset.tile_size = Vector2i(64, 32)
	tileset.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	
	var source = TileSetAtlasSource.new()
	source.texture = load("res://assets/city_isometric.png")
	source.texture_region_size = Vector2i(64, 96)
	
	source.create_tile(Vector2i(0, 0))
	source.create_tile(Vector2i(1, 0))
	source.create_tile(Vector2i(2, 0))
	source.create_tile(Vector2i(3, 0))
	tileset.add_source(source)
	return tileset

func generate_cities() -> void:
	while TerrainMap.singleton_instance == null:
		OS.delay_msec(10)
	var locations: Array[Vector2i] = []
	var tries: int = 0
	
	while locations.size() < 10:
		tries += 1
		if (tries > 1000):
			break
		
		var check_validity = func (rand_location: Vector2i):
			for location: Vector2i in locations:
				if (location.distance_to(rand_location) < 30):
					return false
			return true
		
		@warning_ignore("integer_division")
		var rand_x = randi_range(-map_size.x / 2 + 1, map_size.x / 2 - 1)
		@warning_ignore("integer_division")
		var rand_y = randi_range(-map_size.y / 2 + 1, map_size.y / 2 - 1)
		var rand_tile = Vector2i(rand_x, rand_y)
		if (check_validity.call(rand_tile)):
			locations.push_front(rand_tile)
		
	for location: Vector2i in locations:
		generate_city(location)

func generate_city(location: Vector2i) -> void:
	var terrain_map: TerrainMap = TerrainMap.get_instance()
	var height: int = terrain_map.get_cell(location).height
	set_cell(location, Vector2i(0, 0), height)
	print(location)
