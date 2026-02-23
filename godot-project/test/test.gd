extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var x: RealTile = RealTile.new(Vector2i(0, 0))
	var y: RealTile = RealTile.new(Vector2i(0, 0))
	var d: Dictionary[RealTile, int] = {}
	d[x] = 1
	d[y] = 2
	print(d[x])
	print(d[y])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
