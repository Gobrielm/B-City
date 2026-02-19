class_name TileInfo extends RefCounted

var atlas: Vector2i
var height: int

func _init(p_atlas: Vector2i = Vector2i(0, 0), p_height: int = -1) -> void:
	atlas = p_atlas
	height = p_height

func is_half_tile() -> bool:
	return atlas.x % 2 == 1

func is_water() -> bool:
	return atlas == Vector2i(5, 0) or atlas == Vector2i(4, 0)
