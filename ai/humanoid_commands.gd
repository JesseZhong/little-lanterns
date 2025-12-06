class_name HumanoidCommands

const STEP_DISTANCE = 36


## Have character walk to a random location near the patrol point.
static func wander_patrol(
	target_position: Vector2,
	walk_distance: float,
	fan_angle: float,
	pause_time: float,
) -> Array[Callable]:
	return [
		func(ai_controller: AiController):
			ai_controller.wait(pause_time)
			return AiConstants.EndConditions.WAITED,
		func(ai_controller: AiController):
			# Walk randomly around target position.
			var angle_to_patrol_point = (target_position - ai_controller.character.position).angle()
			var half_fan_angle = fan_angle / 2
			var direction = randf_range(-half_fan_angle, half_fan_angle) + angle_to_patrol_point
			(
				ai_controller
				. move_to(
					(
						VectorMath
						. extend(
							ai_controller.character.position,
							walk_distance,
							direction,
						)
					),
					'walk',
				)
			)
			return AiConstants.EndConditions.DESTINATION_REACHED,
	]


## Close in on the target, from an angle that can be attacked from.
static func rush(
	target: AiTarget,
	abs_main_offset: float,
	secondary_offset: float
) -> Callable:
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

		ai_controller.move_to(
			target_position,
			'run'
		)

		#_run_to(ai_target.position + Vector2(10, 10))
		return AiConstants.EndConditions.DESTINATION_REACHED


# Checks if the target is in range and only strikes if they are.
# Requires directional sense on the character.
static func careful_strike(target: AiTarget) -> Callable:
	return func(ai_controller: AiController):
		var sense = ai_controller.character.attack_sense
		if sense:
			var direction = sense.where_target(target.controller)
			if direction:
				ai_controller.character.turn(direction)
				ai_controller.character.act('light_attack')
				return AiConstants.EndConditions.ACTION_COMPLETED

		ai_controller.go_next()
		return AiConstants.EndConditions.SKIPPED


static func stalk(target: AiTarget, distance: float):
	return func (ai_controller: AiController):
		var target_position = VectorMath.extend(
			ai_controller.character.position,
			distance,
			target.move_direction.angle()
		)

		ai_controller.move_to(
			target_position,
			'walk'
		)

		return AiConstants.EndConditions.DESTINATION_REACHED


static func circle(
	ai_controller: AiController,
	target_position: Vector2,
	distance: float,
	clockwise: bool,
	move_type: String,
) -> Array[Callable]:
	assert(distance > 0, '')

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

	# Calculate the path the character will take
	# and populate the commands to return.
	for i in range(1, steps + 1):
		var angle = step_angle * i + start_angle
		var x = center.x + radius * cos(angle)
		var y = center.y + radius * sin(angle)

		result.append(
			func(ac: AiController):
				ac.move_to(Vector2(x, y), move_type)
				return AiConstants.EndConditions.DESTINATION_REACHED
		)

	assert(steps == len(result))
	return result
