class_name VectorMath
extends RefCounted


static func extend(vector: Vector2, length: float, angle: float) -> Vector2:
	var direction = Vector2.RIGHT.rotated(angle)
	var offset = direction * length
	return vector + offset


static func calc_face_direction(vector: Vector2, name = false) -> Variant:
	var normalized = vector.normalized()
	if normalized == Vector2.ZERO:
		if name:
			return 'down'
		else:
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
