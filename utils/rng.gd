class_name RNG
extends RefCounted

static var _instance = RNG.new()

var _rng: RandomNumberGenerator


func _init():
	_rng = RandomNumberGenerator.new()
	_rng.randomize()


static func decide(...options):
	assert(
		(
			options is Array
			and options.all(
				func(o): return o is Array and len(o) == 2 and o[0] is float and o[1] is Callable
			)
		)
	)

	var weights = []
	for option in options:
		weights.append(option[0])

	var result = _instance._rng.rand_weighted(weights)
	print(result)

	if result > 0:
		(options[result][1] as Callable).call()
