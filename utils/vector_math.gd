class_name VectorMath
extends RefCounted


enum RelativeMovement {
	Toward = 0x1,
	Away = 0x2,
	Parallel = 0x4,
}


static func extend(vector: Vector2, length: float, angle: float) -> Vector2:
	var direction = Vector2.RIGHT.rotated(angle)
	var offset = direction * length
	return vector + offset


static func calc_face_direction(vector: Vector2, name = false) -> Variant:
	var normalized = vector.normalized()
	if normalized == Vector2.ZERO:
		if name:
			return 'down'
		return Vector2.DOWN

	var dot_down = normalized.dot(Vector2.DOWN)
	var dot_up = normalized.dot(Vector2.UP)
	var dot_left = normalized.dot(Vector2.LEFT)
	var dot_right = normalized.dot(Vector2.RIGHT)

	var most_aligned = max(
		dot_down,
		dot_up,
		dot_left,
		dot_right,
	)

	if name:
		match most_aligned:
			dot_up:
				return 'up'
			dot_left:
				return 'left'
			dot_right:
				return 'right'
			dot_down, _:
				return 'down'
	else:
		match most_aligned:
			dot_up:
				return Vector2.UP
			dot_left:
				return Vector2.LEFT
			dot_right:
				return Vector2.RIGHT
			dot_down, _:
				return Vector2.DOWN


static func relative_movement(
	check_condition: int,
	parallel_threshold: float,
	a_position: Vector2,
	b_position: Vector2,
	a_velocity: Vector2,
	b_velocity: Vector2 = Vector2.ZERO,
) -> bool:
	var relative_velocity = a_velocity - b_velocity
	var relative_position = a_position - b_position

	match relative_velocity.dot(relative_position):
		var d when (abs(d) <= (parallel_threshold / 2)) and check_condition & RelativeMovement.Parallel:
			return true
		var d when d > 0 and check_condition & RelativeMovement.Away:
			return true
		var d when d < 0 and check_condition & RelativeMovement.Toward:
			return true
		_:
			return false