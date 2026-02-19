class_name Person extends Sprite2D

var route: Array[RealTile]
const speed_mult: float = 10

func set_route(p_route: Array[RealTile]) -> void:
	route = p_route

func has_reached_destination() -> bool:
	return route.is_empty()

func _process(delta: float) -> void:
	if (route.is_empty()):
		return
	var target: Vector2 = TerrainMap.get_instance().get_local_from_cell(route.front() as RealTile)
	var new_pos: Vector2 = position.move_toward(target, delta * speed_mult)
	position = new_pos
	
	if (position.distance_to(target) < 1):
		route.pop_front()
