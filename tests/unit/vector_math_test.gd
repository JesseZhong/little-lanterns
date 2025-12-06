extends GutTest

var extend_vector_params = (
	ParameterFactory
	. named_parameters(
		['vector', 'length', 'angle', 'expected_result'],
		[
			[Vector2.ZERO, 3, PI / 4, Vector2(2.1213, 2.1213)],
			[Vector2.ZERO, 7, PI, Vector2(-7, 0)],
			[Vector2(2.5, 9.8), 4, 4 * PI / 3, Vector2(0.5, 6.3359)],
		]
	)
)

var calc_face_direction_params = (
	ParameterFactory
	. named_parameters(
		['vector', 'expected_direction', 'expect_name'],
		[
			[Vector2.ZERO, Vector2.DOWN, 'down'],
			[Vector2.DOWN, Vector2.DOWN, 'down'],
			[Vector2.UP, Vector2.UP, 'up'],
			[Vector2.LEFT, Vector2.LEFT, 'left'],
			[Vector2.RIGHT, Vector2.RIGHT, 'right'],
			[Vector2(8, 3), Vector2.RIGHT, 'right'],
			[Vector2(1, -4), Vector2.UP, 'up'],
			[Vector2(-5, 0), Vector2.LEFT, 'left'],
			[Vector2(-27, -6), Vector2.LEFT, 'left'],
		]
	)
)

var relative_movement_params = (
	ParameterFactory
	. named_parameters(
		['check_condition', 'a_position', 'b_position', 'a_velocity', 'b_velocity', 'expected_result'],
		[
			[VectorMath.RelativeMovement.Away, Vector2(22, 0), Vector2(40, 0), Vector2(2, 0), Vector2.ZERO, true],
			[VectorMath.RelativeMovement.Away | VectorMath.RelativeMovement.Parallel, Vector2(22, 0), Vector2(40, 0), Vector2(2, 0), Vector2.ZERO, true],
			[VectorMath.RelativeMovement.Toward | VectorMath.RelativeMovement.Parallel, Vector2(22, 0), Vector2(40, 0), Vector2(2, 0), Vector2.ZERO, false]
		]
	)
)


func test_extend_vector(params = use_parameters(extend_vector_params)):
	var result = VectorMath.extend(params.vector, params.length, params.angle)

	assert_almost_eq(result, params.expected_result, Vector2(0.001, 0.001))


func test_assert_calc_face_direction(params = use_parameters(calc_face_direction_params)):
	var result1 = VectorMath.calc_face_direction(params.vector)
	var result2 = VectorMath.calc_face_direction(params.vector, true)

	assert_eq(result1, params.expected_direction)
	assert_eq(result2, params.expect_name)


func test_relative_movement(params = use_parameters(relative_movement_params)):
	var result = VectorMath.relative_movement(
		params.check_condition,
		params.a_position,
		params.b_position,
		params.a_velocity,
		params.b_position,
	)

	assert_eq(result, params.expected_result)
