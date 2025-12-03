extends Character2D

# TODO: Create passive skill that hones attacks, narrowing deviation.
# Blood effect. Varying effect levels based off severity. Crit is maxish value.
static var _light_attack_modifier_rng = NormalDistRange.new(0.64, 0.2, 0.0, 0.79)
static var _heavy_attack_modifier_rng = NormalDistRange.new(0.64, 0.2, 0.0, 0.79)
static var _charge_attack_modifier_rng = NormalDistRange.new(0.64, 0.2, 0.0, 0.79)


func _ready() -> void:
	super._ready()


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


func trigger_charge_attack() -> void:
	if _attack_area:
		_attack_area.trigger_effect(
			func(target: Character2D) -> void:
				var damage = _character_condition.attack.value * _charge_attack_modifier_rng.value
				target.condition.current_hp -= damage
		)


func _process_additional_actions(action: String) -> bool:
	match action:
		'heavy_attack':
			_move_direction = Vector2.ZERO
			_smooth_play('heavy_attack_%s' % _face_direction)
			return true
		'charge_attack':
			_move_direction = Vector2.ZERO
			_smooth_play('charge_attack_%s' % _face_direction)
			return true
		_:
			return false
