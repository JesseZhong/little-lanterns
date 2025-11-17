extends GutTest

var character: Character2D

func before_each():
  character = partial_double(Character2D).new()

var calc_face_direction_params = ParameterFactory.named_parameters(
  ['vector', 'expected_direction'],
  [
    [Vector2.ZERO,  'down'],
    [Vector2.DOWN,  'down'],
    [Vector2.UP,    'up'],
    [Vector2.LEFT,  'left'],
    [Vector2.RIGHT, 'right'],
    [Vector2(8, 3), 'right'],
    [Vector2(1, -4), 'up'],
    [Vector2(-5, 0), 'left'],
    [Vector2(-27, -6), 'left']
  ]
)

func test_assert_calc_face_direction(params = use_parameters(calc_face_direction_params)):
  var result = character.calc_face_direction(params.vector)
  assert_eq(result, params.expected_direction)
