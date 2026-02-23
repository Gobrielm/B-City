class_name Person extends Sprite2D

var route: Array[RealTile]
var queued_for_deletion: bool = false
var random_offset: Vector2 = Vector2(0, 0)
const speed_mult: float = 10

func _init() -> void:
	offset = Vector2(0, -24)

func set_route(p_route: Array[RealTile]) -> void:
	route = p_route

func set_random_offset(p_random_offset: Vector2) -> void:
	random_offset = p_random_offset

func has_reached_destination() -> bool:
	return route.is_empty()

func get_current_target() -> RealTile:
	if (has_reached_destination()): return null
	return route.front() as RealTile

func _process(delta: float) -> void:
	if (has_reached_destination()):
		if (!queued_for_deletion): CityMap.get_instance().append_person_to_remove(get_instance_id())
		queued_for_deletion = true
		return
	var target: Vector2 = TerrainMap.get_instance().get_local_from_cell(route.front() as RealTile) + Vector2(0, 24)
	var new_pos: Vector2 = position.move_toward(target, delta * speed_mult)
	position = new_pos
	
	if (position.distance_to(target) < 1):
		route.pop_front()
