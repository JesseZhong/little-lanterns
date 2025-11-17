extends GutTest
  
var set_current_hp_params = ParameterFactory.named_parameters(
  ['value', 'max_hp', 'expected_get'],
  [
    [5, 10, 5],
    [200, 150, 150],
    [-3, 100, 0]
  ]
)

func test_assert_set_current_hp(params = use_parameters(set_current_hp_params)):
  var stats = add_child_autofree(CharacterStats.new(
      params.max_hp,
      10,
      1.2,
      10,
    ))
  
  var condition = add_child_autofree(CharacterCondition.new(stats))
  
  condition.current_hp = params.value
  
  assert_eq(condition.current_hp, params.expected_get)
  
func test_assert_set_current_hp_signals_health_changed():
  var stats = add_child_autofree(CharacterStats.new(
      20,
      10,
      1.2,
      10,
    ))
  var condition = add_child_autofree(CharacterCondition.new(stats))
  
  watch_signals(condition)
  condition.current_hp = 15
  
  assert_signal_emitted_with_parameters(condition.health_changed, [20, 15])
  
func test_assert_set_zero_current_hp_signals_death():
  var stats = add_child_autofree(CharacterStats.new(
      20,
      10,
      1.2,
      10,
    ))
  var condition = add_child_autofree(CharacterCondition.new(stats))
  
  watch_signals(condition)
  condition.current_hp = 0
  
  assert_signal_emitted(condition.death)

func test_assert_set_zero_current_hp_signals_death_once():
  var stats = add_child_autofree(CharacterStats.new(
      20,
      10,
      1.2,
      10,
    ))
  var condition = add_child_autofree(CharacterCondition.new(stats))
  
  watch_signals(condition)
  condition.current_hp = 0
  condition.current_hp = 0
  condition.current_hp = 0
  
  assert_signal_emit_count(condition.death, 1)
