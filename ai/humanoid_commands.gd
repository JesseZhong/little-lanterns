class_name HumanoidCommands

const STEP_DISTANCE = 36


static func approach(
	target: AiTarget,
	distance: float,
	move_type: String,
	debug: bool = false,
) -> Callable:
	_debug(debug, 'approach')
	return func (ai_controller: AiController):
		var current_position = ai_controller.character.position
		var angle_of_approach = (target.position - current_position).angle()
		var target_position = VectorMath.extend(
				current_position,
				distance,
				angle_of_approach,
			)
		_debug(debug, 'approach: moving to %s' % target_position)
		ai_controller.move_to(
			target_position,
			move_type,
		)

		return AiConstants.EndConditions.DESTINATION_REACHED


# Checks if the target is in range and only strikes if they are.
# Requires directional sense on the character.
static func careful_strike(
	target: AiTarget,
	strike_type: String,
	debug: bool = false,
) -> Callable:
	_debug(debug, 'careful strike')
	return func(ai_controller: AiController):
		var sense = ai_controller.character.attack_sense
		if sense:
			var direction = sense.where_target(target.controller)
			if direction:
				_debug(
					debug,
					'careful strike: turn toward %s and striking with %s' % [direction, strike_type]
				)
				ai_controller.character.turn(direction)
				ai_controller.character.act(strike_type)
				return AiConstants.EndConditions.ACTION_COMPLETED

		_debug(debug, 'careful strike: go next')
		ai_controller.go_next()
		return AiConstants.EndConditions.SKIPPED


static func circle(
	ai_controller: AiController,
	target_position: Vector2,
	distance: float,
	clockwise: bool,
	move_type: String,
	debug: bool = false,
) -> Array[Callable]:
	_debug(debug, 'circle: %s' % move_type)
	assert(distance > 0, 'Distance must be positive.')

	# Account for remainder.
	var steps = floor(distance / STEP_DISTANCE) + 1
	var result: Array[Callable] = []

	# Quick maths.
	var center = target_position
	var position = ai_controller.character.position
	var diff = position - center
	var start_angle = diff.angle()
	var radius = diff.length()
	var travel_angle = distance / radius * (-1 if clockwise else 1)
	var step_angle = travel_angle / steps
	var num_of_steps = steps + 1

	# Calculate the path the character will take
	# and populate the commands to return.
	for i in range(1, num_of_steps):
		var angle = step_angle * i + start_angle
		var x = center.x + radius * cos(angle)
		var y = center.y + radius * sin(angle)

		result.append(
			func(ac: AiController):
				var step_position = Vector2(x, y)
				_debug(
					debug,
					'circle: moving %s/%s to %s' % [i, num_of_steps, step_position]
				)
				ac.move_to(step_position, move_type)
				return AiConstants.EndConditions.DESTINATION_REACHED
		)

	assert(steps == len(result))
	return result


static func evade_strike(
	ai_controller: AiController,
	target: AiTarget,
	evade_distance: float,
	strike_type: String,
	debug: bool = false,
) -> Array[Callable]:
	_debug(debug, 'evade strike')

	# Calculate before hand. The command should be 'atomic'.
	var current_position = ai_controller.character.position
	var vector_of_approach = VectorMath.calc_face_direction(
		current_position - target.position)

	return [
		func (_ac):
			var target_position = current_position + (vector_of_approach * evade_distance)
			_debug(debug, 'evade strike: moving to %s' % target_position)
			ai_controller.move_to(
				target_position,
				'run'
			)
			return AiConstants.EndConditions.DESTINATION_REACHED,

		func (_ac):
			var face_direction = vector_of_approach * -1
			_debug(
				debug,
				'evade strike: turning toward %s and striking with %s' % [face_direction, strike_type]
			)
			ai_controller.character.turn(face_direction)
			ai_controller.character.act(strike_type)
			return AiConstants.EndConditions.ACTION_COMPLETED
	]


static func pause(time: float, debug: bool = false):
	_debug(debug, 'pause')
	return func(ai_controller: AiController):
		_debug(debug, 'pause: time of %s' % time)
		ai_controller.wait(time)
		return AiConstants.EndConditions.WAITED


## Close in on the target, from an angle that can be attacked from.
static func rush(
	target: AiTarget,
	abs_main_offset: float,
	secondary_offset: float,
	debug: bool = false,
) -> Callable:
	_debug(debug, 'rush')
	return func(ai_controller: AiController):
		var target_position = target.position

		var vector_of_approach = VectorMath.calc_face_direction(
			ai_controller.character.position - target_position)

		match vector_of_approach:
			Vector2.UP:
				target_position += Vector2(secondary_offset, -abs_main_offset)
			Vector2.DOWN:
				target_position += Vector2(secondary_offset, abs_main_offset)
			Vector2.RIGHT:
				target_position += Vector2(abs_main_offset, secondary_offset)
			Vector2.LEFT:
				target_position += Vector2(-abs_main_offset, secondary_offset)

		_debug(debug, 'rush: moving towards %s' % target_position)
		ai_controller.move_to(
			target_position,
			'run'
		)

		#_run_to(ai_target.position + Vector2(10, 10))
		return AiConstants.EndConditions.DESTINATION_REACHED


static func stalk(target: AiTarget, distance: float, debug: bool = false):
	_debug(debug, 'stalk')
	return func (ai_controller: AiController):
		var target_position = VectorMath.extend(
			ai_controller.character.position,
			distance,
			target.move_direction.angle()
		)

		_debug(debug, 'stalk: moving toward %s' % target_position)
		ai_controller.move_to(
			target_position,
			'walk'
		)

		return AiConstants.EndConditions.DESTINATION_REACHED


## Have character walk to a random location near the patrol point.
static func wander_patrol(
	patrol_position: Vector2,
	walk_distance: float,
	fan_angle: float,
	pause_time: float,
	debug: bool = false,
) -> Array[Callable]:
	_debug(debug, 'wander patrol')
	return [
		pause(pause_time, debug),
		func(ai_controller: AiController):
			# Walk randomly around target position.
			var angle_to_patrol_point = (patrol_position - ai_controller.character.position).angle()
			var half_fan_angle = fan_angle / 2
			var direction = randf_range(-half_fan_angle, half_fan_angle) + angle_to_patrol_point
			var target_position = VectorMath.extend(
				ai_controller.character.position,
				walk_distance,
				direction,
			)
			_debug(debug, 'wander patrol: moving toward %s' % target_position)
			(
				ai_controller
				. move_to(
					target_position,
					'walk',
				)
			)
			return AiConstants.EndConditions.DESTINATION_REACHED,
	]


static func _debug(debug: bool, name: String):
	if debug:
		print(name)