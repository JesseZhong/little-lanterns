@abstract class_name Character2D
extends Node2D

const CHARACTER_PLANE: int = 20

signal on_hit

var move_velocity: Vector2 = Vector2.ZERO
var action: String = 'idle'

# Internally used.
var anim_player: AnimationPlayer
var character_body: CharacterBody2D
var block_anim: bool = false

var current_position:
  get:
    return character_body.position \
      if character_body \
      else Vector2.ZERO
  set(value):
    if character_body:
      character_body.position = value

func stand(_delta: float):
  smooth_play('idle')

func move(_delta: float):
  if move_velocity.length() > 0:
    var x = move_velocity.x
    var y = move_velocity.y
    if abs(y) > abs(x):
      if y > 0:
        smooth_play('walk_down')
      elif y < 0:
        smooth_play('walk_up')
    else:
      if x > 0:
        smooth_play('walk_right')
      elif x < 0:
        smooth_play('walk_left')

func get_hit(_delta: float):
  var direction = calc_face_direction(move_velocity)
  smooth_play('hit_%s' % direction)
  
func light_attack(_delta: float):
  var direction = calc_face_direction(move_velocity)
  smooth_play('light_attack_%s' % direction)

func smooth_play(animation_name: String):
  if animation_name != anim_player.assigned_animation:
    anim_player.play("RESET")
    anim_player.advance(0)
  anim_player.play(animation_name)

func calc_face_direction(vector: Vector2) -> String:
  match(vector):
    var v when v.normalized().dot(Vector2.DOWN) > 0: 
      return 'down'
    var v when v.normalized().dot(Vector2.UP) > 0:
      return 'up'
    var v when v.normalized().dot(Vector2.LEFT) > 0:
      return 'left'
    var v when v.normalized().dot(Vector2.RIGHT) > 0:
      return 'right'
    _:
      return 'down'
      
func process_additional_actions(_delta: float) -> bool:
  return false
  
func block_animations():
  block_anim = true

func unblock_animations():
  block_anim = false

func _ready() -> void:
  anim_player = $AnimationPlayer
  character_body = $CharacterBody2D
  
  # Ensure all characters and controllers are on the same plane.
  z_index = CHARACTER_PLANE
  
  # Enable Y-Sorting to draw furthest characters first.
  y_sort_enabled = true

func _process(delta: float) -> void:
  # Determine the animation based off the
  # intended action and if animations are blocked.
  if anim_player:
    if block_anim:
      if action == 'get_hit':
        get_hit(delta)
    else:
      match(action):
        'stand':
          stand(delta)
        'move':
          move(delta)
        'light_attack':
          light_attack(delta)
        _:
          if not process_additional_actions(delta):
            stand(delta)

func _physics_process(delta: float) -> void:
  if character_body:
    character_body.move_and_collide(move_velocity * delta)
