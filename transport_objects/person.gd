class_name Person extends Sprite2D

var route: Array[Vector2]
const speed: float = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_route(p_route: Array[Vector2]) -> void:
	route = p_route

func has_reached_destination() -> bool:
	return route.is_empty()

func _process(delta: float) -> void:
	if (route.is_empty()):
		return
	var target: Vector2 = route.front()
	var new_pos: Vector2 = position.move_toward(target, delta)
	position = new_pos
	
	if (position.distance_to(target) < 1):
		route.pop_front()
