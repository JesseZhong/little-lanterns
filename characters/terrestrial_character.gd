class_name TerrestrialCharacter
extends Character2D

func _process_action(action: String) -> bool:
	if super._process_action(action):
		return true

	match action:
		'walk':
			_move_speed = _character_condition.walk_speed
			return true
		'run':
			_anim_player.speed_scale = _character_condition.run_modifier.value
			_move_speed = _character_condition.run_speed
			return true
		'light_attack':
			_move_power = 0.0
			return true
	return false
