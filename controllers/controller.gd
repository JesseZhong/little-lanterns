@abstract class_name Controller
extends Node2D

@export var character_scene: PackedScene
var character: Character2D

var current_position: Vector2 = Vector2.ZERO:
  get:
    return character.current_position \
      if character \
      else Vector2.ZERO
      
@export
var start_position: Vector2 = Vector2.ZERO

func _ready() -> void:
  character = character_scene.instantiate()
  character.current_position = start_position
  add_child(character)
  
  # Enable Y-Sorting to draw furthest characters first.
  y_sort_enabled = true
  
