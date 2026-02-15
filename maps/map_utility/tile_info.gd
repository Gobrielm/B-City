class_name TileInfo extends RefCounted

var atlas: Vector2i
var height: float

func _init(p_atlas: Vector2i = Vector2i(0, 0), p_height: float = -1) -> void:
	atlas = p_atlas
	height = p_height
