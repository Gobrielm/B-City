class_name Person extends Sprite2D

var current_tile: RealTile = null

var route: Array[RealTile] = []
var queued_for_deletion: bool = false
var random_offset: Vector2 = Vector2(0, 0)
var changed: bool = false
const speed_mult: float = 20

var household: House = null

func adjust_offset() -> void:
	var other_tile: RealTile = current_tile if route.is_empty() else route.front()
	
	var closest_tile: RealTile = TerrainMap.get_instance().get_closest_tile_between_two(current_tile, other_tile, position + get_pathing_offset())
	if (closest_tile == null): return
	var tile_info: TileInfo = TerrainMap.get_instance().get_cell(closest_tile)
	if (tile_info == null): return
	
	var new_offset: Vector2 = Vector2(0, -tile_info.height * 16)
	if CityMap.get_instance().is_building(closest_tile):
		new_offset.y += 12
	
	if (offset != new_offset and not changed):
		var change_neg: bool = offset.y - new_offset.y > 0
		var mult: int = 1 if change_neg else -1
		position += (offset - new_offset + Vector2(0, 16 * mult))
		changed = true
		offset = new_offset

func get_pathing_offset() -> Vector2:
	return -offset * 2 - Vector2(0, 16) + random_offset

func set_route(p_route: Array[RealTile]) -> void:
	route = p_route

func move_to_initial_pos() -> void:
	if (!route.is_empty()):
		var start_tile: RealTile = route.front() as RealTile
		route.pop_front()
		set_pos(start_tile)

func set_random_offset(p_random_offset: Vector2) -> void:
	random_offset = p_random_offset

func has_reached_destination() -> bool:
	return route.is_empty()

func get_current_target() -> RealTile:
	if (has_reached_destination()): return null
	return route.front() as RealTile

func set_pos(start_tile: RealTile) -> void:
	current_tile = start_tile
	adjust_offset()
	position = TerrainMap.get_instance().get_local_from_cell(start_tile) + get_pathing_offset()

func _process(delta: float) -> void:
	if (has_reached_destination()):
		if (!queued_for_deletion): CityMap.get_instance().append_person_to_remove(get_instance_id())
		queued_for_deletion = true
		return
		
	adjust_offset()
	var target: Vector2 = TerrainMap.get_instance().get_local_from_cell(route.front() as RealTile) + get_pathing_offset()
	var new_pos: Vector2 = position.move_toward(target, delta * speed_mult)
	position = new_pos
	
	if (position.distance_to(target) < 1):
		current_tile = route.front()
		route.pop_front()
		changed = false
