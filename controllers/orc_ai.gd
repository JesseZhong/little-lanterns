extends AIController

const ATTENTION = {
  range = 220,
  low_att_dist = 140,
}

var _keep_attention_rng = NormalDistRange.new(40, 1.4, 35, 45)
var _close_modifier_rng = NormalDistRange.new(0.4, 0.0024, 0.38, 0.42)
var _far_modifier_rng = NormalDistRange.new(0.2, 0.0016, 0.19, 0.21)
var _hp_modifier_rng = NormalDistRange.new(0.3, 0.02, 0.15, 0.45)
var _hits_modifier_rng = NormalDistRange.new(0.5, 0.015, 0.4, 0.6)
var _damage_modifier_rng = NormalDistRange.new(0.6, 0.018, 0.5, 0.7)
var _walk_distance_rng = NormalDistRange.new(54, 3.2, 40, 65)

func _ready() -> void:
  super._ready()
  
func setup(
  own_character: Character2D,
  own_condition: CharacterCondition,
  ...args
):
  super.setup(
    own_character,
    own_condition,
    # Create the monitoring areas.
    _setup_ai_area(120, 2.4, 112, 128),
    _setup_ai_area(ATTENTION.range, 3.1, 208, 232),
    args,
  )

func _process_targets(delta_since: float) -> void:
  if len(_targets):
    Query.foreach(
      _targets,
      func (key: NodePath, data: AiTarget) -> void:
        var weight = 0.0
        var target_condition = data.condition
        
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
  pass
    
func _process_actions(delta: float) -> bool:
  return true
 
func _process_current_target(delta: float) -> void:
  pass

func _stalk(target: AiTarget):
  var target_position = target.position
  var target_face_direction = target.controller.character.move_direction
  
  position.cross(target_position)
