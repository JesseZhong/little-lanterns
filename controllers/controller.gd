@abstract class_name Controller
extends Node2D

@export var character_scene: PackedScene
var character: Character2D

@export
var current_position: Vector2 = Vector2.ZERO:
  get:
    return character.current_position \
      if character \
      else Vector2.ZERO
  set(value):
    if character:
      character.current_position = value

func _ready() -> void:
  character = character_scene.instantiate()
  add_child(character)
  
  # Enable Y-Sorting to draw furthest characters first.
  y_sort_enabled = true
  
