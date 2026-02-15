from py4godot.methods import private
from py4godot.signals import signal, SignalArg
from py4godot.classes import gdclass
from py4godot.classes.core import Vector3
from py4godot.classes.core import Array
from py4godot.classes.Node2D import Node2D

@gdclass
class LinearTestClass(Node2D):

	x: list = [1, 2, 3, 4, 5]
	y: list = [2, 4, 6, 8, 10]

	# define properties like this
	test_int: int = 5
	test_float: float = 5.2
	test_bool: bool = True
	test_vector: Vector3 = Vector3.new3(1,2,3)

	# define signals like this
	test_signal = signal([SignalArg("test_arg", int)])


	def _ready(self) -> None:
		self.learning_rate = 0.01
		self.epochs = 1000
		self.m = 0.0  # slope
		self.b = 0.0  # intercept

	def _process(self, delta: float) -> None:
		pass
		# put dynamic code here

	# Hide the method in the godot editor
	@private
	def test_method(self):
		pass
	
	def test(self) -> float:
		return 10.0

	def predict(self, x: float) -> float:
		"""
		x: float or list of floats
		"""
		if isinstance(x, list):
			return [self.m * xi + self.b for xi in x]
		return self.m * x + self.b

	def fit(self, xArray: Array, yArray: Array):
		"""
		x, y: lists of floats of equal length
		"""
		x = self.godot_array_to_python_list(xArray)
		y = self.godot_array_to_python_list(yArray)

		n = len(x)

		for _ in range(self.epochs):
			dm = 0.0
			db = 0.0

			for xi, yi in zip(x, y):
				y_pred = self.m * xi + self.b
				error = y_pred - yi
				dm += error * xi
				db += error

			# Average gradients
			dm /= n
			db /= n

			# Gradient descent update
			self.m -= self.learning_rate * dm
			self.b -= self.learning_rate * db
	
	@private
	def godot_array_to_python_list(self, a: Array) -> list:
		new_list = []
		for i in range(0, a.size()):
			new_list.append(a[i])
		return new_list
