class_name CharacterCondition
extends Node

signal health_changed
signal death

var character_stats: CharacterStats

func _init(stats: CharacterStats) -> void:
  if not stats or stats is not CharacterStats:
    print_debug('Error: Invalid character stats passed to character condition.')
    return
  character_stats = stats
  movement_speed = Stat.new(stats, func(s: CharacterStats): return s.movement_speed)
  run_modifier = Stat.new(stats, func(s: CharacterStats): return s.run_modifier)
  max_hp = Stat.new(stats, func(s: CharacterStats): return s.max_hp)
  attack = Stat.new(stats, func(s: CharacterStats): return s.attack)

var walk_speed: float:
  get:
    if not movement_speed:
      return 0.0
    return movement_speed.value

var run_speed: float:
  get:
    if not movement_speed or not run_modifier:
      return 0.0
    return movement_speed.value * run_modifier.value

var movement_speed: Stat

var run_modifier: Stat

## Current max HP. Can't go below 0.
var max_hp: Stat

## Current HP. Can't go below 0 or abovw the max HP, if set.
## HP changes trigger [health_changed].
## Value reaching 0 triggers [death].
var current_hp: int:
  get:
    if not current_hp:
      current_hp = max_hp.value
    return current_hp
  set(value):
    var previous_hp = current_hp
    current_hp = clamp(max_hp.value, 0, value)
    
    if previous_hp != current_hp:
      health_changed.emit(previous_hp, current_hp)
    
    if current_hp <= 0:
      death.emit()
      
var isAlive: bool:
  get:
    if current_hp:
      return current_hp > 0
    return false
    
var isDead: bool:
  get:
    if current_hp:
      return current_hp <= 0
    return false
    
var attack: Stat

## Maintains a mutable character stat.
class Stat extends Object:
  var _stats: CharacterStats
  var _property: Callable
  var _effects: Dictionary[String, Callable]
  
  func _init(stats: CharacterStats, property: Callable) -> void:
    _stats = stats
    _property = property
    _effects = {}
    
  var value: Variant:
    get:
      var val = _property.call(_stats)
      for effect_name in _effects:
        val = _effects[effect_name].call(val)
      return val
      
  func register_effect(name: String, effect: Callable):
    _effects.set(name, effect)
    
  func unregister_effect(name: String):
    _effects.erase(name)
