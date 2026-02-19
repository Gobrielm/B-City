class_name RealTile extends RefCounted

var tile: Vector2i

func _init(p_tile: Vector2i = Vector2i(0, 0)) -> void:
	tile = p_tile

func add_vector2i(to_add: Vector2i) -> RealTile:
	return RealTile.new(to_add + tile)

func distance_to(real_tile: RealTile) -> float:
	return tile.distance_to(real_tile.tile)
