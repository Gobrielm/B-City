extends Node2D

@onready var linear_test = $LinearTestClass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	linear_test.fit([2, 3, 4, 5, 6, 7], [4, 6, 8, 10, 12, 14])
	print(linear_test.predict(100))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
