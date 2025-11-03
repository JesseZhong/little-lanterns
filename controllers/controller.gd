@abstract class_name Controller
extends Node2D

@export
var character_scene: PackedScene

@export
var start_position: Vector2 = Vector2.ZERO

var current_position: Vector2 = Vector2.ZERO:
  get:
    return _character.current_position \
      if _character \
      else Vector2.ZERO

var _character: Character2D

func _ready() -> void:
  _character = character_scene.instantiate()
  _character.current_position = start_position
  add_child(_character)
  
  # Enable Y-Sorting to draw furthest characters first.
  y_sort_enabled = true
