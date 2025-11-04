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
var _character_condition: CharacterCondition

func _ready() -> void:
  if not _character_condition:
    print_debug('Error: Missing valid character condition for controller.')
    return
  _character = character_scene.instantiate()
  _character.setup(start_position, _character_condition)
  add_child(_character)
  
  # Enable Y-Sorting to draw furthest characters first.
  y_sort_enabled = true

func setup(condition: CharacterCondition) -> void:
  _character_condition = condition
