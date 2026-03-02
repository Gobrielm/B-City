class_name House extends RefCounted

var location: RealTile = null
var population: int = 0
var people_outside: int = 0
var money: int = 0
var used_money: int = 0

func _init(p_location: RealTile, p_population: int) -> void:
	location = p_location
	population = p_population

func process() -> void:
	if randi_range(0, 100) == 0 and are_people_available():
		dispatch_person() 

func are_people_available() -> bool:
	return population > people_outside

func dispatch_person() -> void:
	assert(people_outside < population)
	people_outside += 1
	CityMap.get_instance().spawn_person(location)

func return_person() -> void:
	assert(people_outside > 0)
	people_outside -= 1

func add_money(amt: int) -> void:
	money += amt
