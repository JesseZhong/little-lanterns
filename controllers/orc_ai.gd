extends AIController

const ATTENTION = {
  range = 220,
  low_att_dist = 140,
}

static var _keep_attention_rng = NormalDistRange.new(40, 1.4, 35, 45)
static var _close_modifier_rng = NormalDistRange.new(0.4, 0.0024, 0.38, 0.42)
static var _far_modifier_rng = NormalDistRange.new(0.2, 0.0016, 0.19, 0.21)
static var _hp_modifier_rng = NormalDistRange.new(0.3, 0.02, 0.15, 0.45)
static var _hits_modifier_rng = NormalDistRange.new(0.5, 0.015, 0.4, 0.6)
static var _damage_modifier_rng = NormalDistRange.new(0.6, 0.018, 0.5, 0.7)
static var _walk_distance_rng = NormalDistRange.new(54, 3.2, 40, 65)

static var _idle_interval_rng = NormalDistRange.new(3.0, 0.23, 2.0, 4.0)
var _idle_time: float = 0
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
      _setup_ai_area(120, 2.4, 112, 128),
      _setup_ai_area(ATTENTION.range, 3.1, 208, 232),
      params,
    )
  base_setup.callv(args)
  _patrol_target = own_character.position

func _process_targets(delta_since: float) -> void:
  if len(_targets):
    Query.foreach(
      _targets,
      func (key: NodePath, data: AiTarget) -> void:
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
    )
    
func _process_idle(delta: float):
  _idle_time -= delta
  
  if _idle_time <= 0:
    # Reset idle timer.
    _idle_time = _idle_interval_rng.value

    # Have character walk to a random location near the patrol point.
    var angle_to_patrol_point = position.angle_to(_patrol_target)

    var direction = randf_range(-PI / 8, PI / 8) + angle_to_patrol_point

    _walk_to(VectorMath.extend(position, _walk_distance_rng.value, direction))


func _process_current_target(_delta: float, ai_target: AiTarget) -> void:
  _enqueue_action(
    func ():
      _run_to(ai_target.position + Vector2(10, 10))
  )

func _stalk(target: AiTarget):
  var target_position = target.position
  var target_face_direction = target.controller.character.move_direction
  
  position.cross(target_position)

func _circle(target: AiTarget):
  pass
