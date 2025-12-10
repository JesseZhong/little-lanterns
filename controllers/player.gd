class_name Player
extends Controller


func _ready() -> void:
	super._ready()


func _process(_delta: float) -> void:
	if _character:
		var direction: Vector2 = Vector2.ZERO
		direction.x += Input.get_action_strength('right')
		direction.x -= Input.get_action_strength('left')
		direction.y += Input.get_action_strength('down')
		direction.y -= Input.get_action_strength('up')
		var direction_normalized = direction.normalized()
		var direction_length = direction_normalized.length()

		var action: String = ''
		var move_power: float = 0.0
		if Input.is_action_pressed('light_attack'):
			action = 'light_attack'
		elif Input.is_action_pressed('heavy_attack'):
			action = 'heavy_attack'
		elif Input.is_action_pressed('charge_attack'):
			action = 'charge_attack'
		elif Input.is_action_pressed('run'):
			action = 'run'
			move_power = direction_length
		else:
			action = 'walk'
			move_power = direction_length

		if direction_length > 0:
			_character.act(action, direction_normalized, move_power)
		else:
			_character.act('idle')
