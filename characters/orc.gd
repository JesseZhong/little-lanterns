extends TerrestrialCharacter

# TODO: Create passive skill that hones attacks, narrowing deviation.
# Blood effect. Varying effect levels based off severity. Crit is maxish value.
var _light_attack_modifier_rng = NormalDistRange.new(0.87, 0.12, 0.0, 1.5)
var _heavy_attack_modifier_rng = NormalDistRange.new(1.4, 0.15, 0.7, 2.3)


func _ready() -> void:
	super._ready()


## Add handling for heavy attack.
func _process_action(action: String) -> bool:
	if super._process_action(action):
		return true

	match action:
		'heavy_attack':
			_move_power = 0.0
			return true
	return false


func trigger_light_attack() -> void:
	if _attack_area:
		_attack_area.trigger_effect(
			func(target: Character2D) -> void:
				var damage = _character_condition.attack.value * _light_attack_modifier_rng.value
				target.condition.current_hp -= damage
		)


func trigger_heavy_attack() -> void:
	if _attack_area:
		_attack_area.trigger_effect(
			func(target: Character2D) -> void:
				var damage = _character_condition.attack.value * _heavy_attack_modifier_rng.value
				target.condition.current_hp -= damage
		)
