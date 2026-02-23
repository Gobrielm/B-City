class_name LocalTile extends RefCounted

var tile: Vector2i

func _init(p_tile: Vector2i = Vector2i(0, 0)) -> void:
	tile = p_tile

func hash() -> Vector2i:
	return tile
