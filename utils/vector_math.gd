class_name VectorMath
extends Node

static func extend(vector: Vector2, length: float, angle: float) -> Vector2:
  var direction = Vector2.RIGHT.rotated(angle)
  var offset = direction * length
  return vector + offset
