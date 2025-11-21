class_name DirectionalSenseArea
extends Node2D

var up: Area2D
var down: Area2D
var left: Area2D
var right: Area2D


func _ready() -> void:
  up = $Up
  down = $Down
  left = $Left
  right = $Right


func where_target(target: Controller) -> Variant:
  var character = target.character
  if not character:
    return null
  
  for up_area in up.get_overlapping_areas():
    if up_area.get_parent() == character:
      return Vector2.UP
      
  for down_area in down.get_overlapping_areas():
    if down_area.get_parent() == character:
      return Vector2.DOWN
      
  for left_area in left.get_overlapping_areas():
    if left_area.get_parent() == character:
      return Vector2.LEFT
      
  for right_area in right.get_overlapping_areas():
    if right_area.get_parent() == character:
      return Vector2.RIGHT
      
  return null
