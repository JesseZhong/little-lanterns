extends GutTest


var _random_number_generator: RandomNumberGenerator


func before_all():
	register_inner_classes(get_script())


func before_each():
	# Mock internal random number generator.
	_random_number_generator = double(RandomNumberGenerator).new()
	RNG._instance._rng = _random_number_generator


func test_decide__first_selected():
	stub(_random_number_generator.rand_weighted).to_return(0)
	var callback_1 = partial_double(Callback).new()
	var callback_2 = partial_double(Callback).new()

	RNG.decide(
		[
			0.2,
			callback_1.method
		],
		[
			12.0,
			callback_2.method
		]
	)

	assert_called(_random_number_generator, 'rand_weighted', [[0.2, 12.0]])
	assert_called(callback_1.method)
	assert_not_called(callback_2.method)


func test_decide__empty():
	stub(_random_number_generator.rand_weighted).to_return(-1)

	RNG.decide()

	assert_called(_random_number_generator, 'rand_weighted', [[]])


func test_coin_flip__zero():
	stub(_random_number_generator.randf).to_return(0)

	var result = RNG.coin_flip()

	assert_false(result)


func test_coin_flip__one():
	stub(_random_number_generator.randf).to_return(1)

	var result = RNG.coin_flip()

	assert_true(result)


class Callback:
	extends RefCounted

	func method():
		pass
