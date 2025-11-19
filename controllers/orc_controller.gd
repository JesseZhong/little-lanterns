extends AiController

const ATTENTION = {
  range = 220,
  low_att_dist = 140,
}

static var _scan_range_rng = NormalDistRange.new(120, 2.4, 112, 128)
static var _attention_range_rng = NormalDistRange.new(ATTENTION.range, 3.1, 208, 232)
static var _keep_attention_rng = NormalDistRange.new(40, 1.4, 35, 45)
static var _close_modifier_rng = NormalDistRange.new(0.4, 0.0024, 0.38, 0.42)
static var _far_modifier_rng = NormalDistRange.new(0.2, 0.0016, 0.19, 0.21)
static var _hp_modifier_rng = NormalDistRange.new(0.3, 0.02, 0.15, 0.45)
static var _hits_modifier_rng = NormalDistRange.new(0.5, 0.015, 0.4, 0.6)
static var _damage_modifier_rng = NormalDistRange.new(0.6, 0.018, 0.5, 0.7)
static var _walk_distance_rng = NormalDistRange.new(54, 3.2, 40, 65)
static var _approach_distance_rng = NormalDistRange.new(12, 0.58, 9, 15)
static var _idle_interval_rng = NormalDistRange.new(3.0, 0.23, 2.0, 4.0)
var _patrol_target: Vector2


func _ready() -> void:
  super._ready()


func setup(
  own_character: Character2D,
  own_condition: CharacterCondition,
  ...args
):
  # Variadic arguments currently don't have a spread operator
  # to compliment it. The workaround is to use `callv` to pass
  # the arguments. Unfortunately, this is the only way to 
  # convert a base/super method into a callable.
  # See: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#variadic-functions
  var base_setup = func (params):
    super.setup(
      own_character,
      own_condition,
      # Create the monitoring areas.
      _scan_range_rng.value,
      _attention_range_rng.value,
      params,
    )
  base_setup.callv(args)
  _patrol_target = own_character.position


func _weigh_target(key: NodePath, data: AiTarget, delta_since: float) -> void:
  var weight = 0.0
  var target_condition = data.condition
  
  # Precaution: If the target doesn't exist anymore, skip.
  if not target_condition:
    return
  
  # See how far the target is to this character.
  # Weigh closer, higher. Also, weigh really far away higher.
  var distance = (data.position as Vector2 - position).length()
  var diff = distance - ATTENTION.low_att_dist
  weight += (abs(diff) * _close_modifier_rng.value) \
    if diff < 0 \
    else _far_modifier_rng.value * diff
  
  # The lower the percentage health, higher attention.
  var percent_hp = target_condition.current_hp / target_condition.max_hp.value
  weight += (1 - percent_hp) * _hp_modifier_rng.value
  
  # Hits taken from target.
  weight += data.hits_taken * _hits_modifier_rng.value
  
  # Damage taken from target.
  weight += data.damage_taken * _damage_modifier_rng.value
  
  # If already current target, maybe maintain.
  if _current_target == key:
    weight += _keep_attention_rng.value
    data.target_time += delta_since
  
  data.weight = weight
  data.attention_time += delta_since


func _idle():
  _queue.do(HumanoidCommands.patrol_wander(
    _patrol_target,
    _walk_distance_rng.value,
    PI,
    _idle_interval_rng.value
  ))


func _engage_target(ai_target: AiTarget, _delta: float) -> void:
  pass
