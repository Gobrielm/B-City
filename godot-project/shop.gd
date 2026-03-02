class_name Shop extends RefCounted

var location: RealTile = null
var resources_available: Array[int] = []
var money: int = 0

func _init(p_location: RealTile) -> void:
	location = p_location

func process() -> void:
	pass

func add_resource(resource: int) -> void:
	resources_available.append(resource)

func are_resources_available() -> bool:
	return !resources_available.is_empty()

func sell_resource(price: int) -> int:
	assert(are_resources_available())
	var resource: int = resources_available.front()
	resources_available.pop_front()
	money += price
	return resource
