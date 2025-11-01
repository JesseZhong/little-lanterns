@abstract class_name Controller
extends Node

@export var character_scene: PackedScene
@export var start_position: Vector2 = Vector2.ZERO
var character: Character2D

var current_position:
  get:
    return character.position if character else Vector2.ZERO

func _ready() -> void:
  character = character_scene.instantiate()
  character.position = start_position
  add_child(character)
