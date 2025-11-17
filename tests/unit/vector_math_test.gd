extends GutTest

var extend_vector_params = ParameterFactory.named_parameters(
  ['vector', 'length', 'angle', 'expected_result'],
  [
    [Vector2.ZERO, 3, PI / 4, Vector2(2.1213, 2.1213)],
    [Vector2.ZERO, 7, PI, Vector2(-7, 0)],
    [Vector2(2.5, 9.8), 4, 4 * PI / 3, Vector2(0.5, 6.3359)],
  ]
)

func test_extend_vector(params = use_parameters(extend_vector_params)):
  var result = VectorMath.extend(params.vector, params.length, params.angle)

  assert_almost_eq(result, params.expected_result, Vector2(0.001, 0.001))
