extends Character2D

# TODO: Create passive skill that hones attacks, narrowing deviation.
# Blood effect. Varying effect levels based off severity. Crit is maxish value.
var _light_attack_modifier_rng = NormalDistRange.new(0.87, 0.12, 0.0, 1.5)

func _ready() -> void:
  super._ready()
  
func trigger_light_attack() -> void:
  if _attack_area:
    _attack_area.trigger_effect(
      func (target: Character2D) -> void:
        var damage = _character_condition.attack.value * _light_attack_modifier_rng.value
        target.condition.current_hp -= damage
        pass
    )
