class_name CharacterStats
extends Node

var max_hp: int
var movement_speed: int
var run_modifier: float
var attack: int

func _init(
  start_max_hp: int,
  start_movement_speed: int,
  start_run_modifier: float,
  start_attack: int
) -> void:
  max_hp = start_max_hp
  movement_speed = start_movement_speed
  run_modifier = start_run_modifier
  attack = start_attack
