@abstract class_name Character2D
extends Node2D

signal on_hit

## Default Z-Index of characters.
const CHARACTER_PLANE: int = 20

## Current position of the character's body.
var current_position:
  get:
    return _character_body.position \
      if _character_body \
      else Vector2.ZERO
  set(value):
    if _character_body:
      _character_body.position = value

## Sets the intended movement direction
## of the character. This will be normalized
## and then modified by a character's speed
## state and then used by physics to determine
## if the character can actually move to
## a new position.
var move_direction: Vector2 = Vector2.ZERO

## Sets the next requested action the character
## should make. The action isn't necessarily
## acted on. Depends on if actions/animations
## are currently blocked by other animations.
var action: String = 'idle'

var _anim_player: AnimationPlayer
var _character_body: CharacterBody2D
var _character_condition: CharacterCondition
var _block_anim: bool = false
var _face_direction: String = 'down'

func _init(condition: CharacterCondition) -> void:
  _character_condition = condition

func _ready() -> void:
  _anim_player = $AnimationPlayer
  _character_body = $CharacterBody2D
  
  # Ensure all characters and controllers are on the same plane.
  z_index = CHARACTER_PLANE
  
  # Enable Y-Sorting to draw furthest characters first.
  y_sort_enabled = true

func _process(delta: float) -> void:
  # Determine the animation based off the
  # intended action and if animations are blocked.
  if _anim_player:
    if _block_anim:
      if action == '_get_hit':
        _get_hit(delta)
    else:
      match(action):
        '_stand':
          _stand(delta)
        '_move':
          _move(delta)
        '_light_attack':
          _light_attack(delta)
        _:
          if not _process_additional_actions(delta):
            _stand(delta)

func _physics_process(delta: float) -> void:
  if _character_body and _character_condition:
    _character_body.move_and_collide(
      move_direction.normalized() * _character_condition.movement_speed * delta)

## Prevent other actions from being played.
## Should be used in [AnimationPlayer] track.
func block_animations():
  _block_anim = true

## Releases block, allowing other actions to be played.
## Should be used in [AnimationPlayer] track.
func unblock_animations():
  _block_anim = false

## Attempts to play an animation.
##
## If a new animation is requested, reset the
## [AnimationPlayer] to use all track defaults
## before switching animations. This ensures
## a clean baseline for the new animation as
## well as reduces the amount of work creating
## each animation.
## If the animation requested is already playing,
## this method will simply keep playing the animation
## with no changes.
func smooth_play(animation_name: String):
  if animation_name != _anim_player.assigned_animation:
    _anim_player.play("RESET")
    _anim_player.advance(0)
  _anim_player.play(animation_name)

func calc_face_direction(vector: Vector2) -> String:
  match(vector):
    var v when v == Vector2.ZERO:
      return 'down'
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

## Sets character to 'idle'.
func _stand(_delta: float):
  smooth_play('idle')

## Attempts to _move and animate the character.
## Also sets the face direction.
func _move(_delta: float):
  if move_direction.length() > 0:
    var x = move_direction.x
    var y = move_direction.y
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
        
    # Preserve the face direction for all other actions.
    _face_direction = calc_face_direction(move_direction)

func _get_hit(_delta: float):
  # TODO: Change to incoming hit direction.
  smooth_play('hit_%s' % _face_direction)
  
## Perform a light attack. Temporarily stop any character movement.
## Can be overridden. For instance, for passive
## characters, override to do nothing.
func _light_attack(_delta: float):
  move_direction = Vector2.ZERO
  smooth_play('light_attack_%s' % _face_direction)
  
## Override to handle additional actions.
## 
## Handles actions not already handled by [Character2D]
## itself. By default, does nothing and returns [false].
## Override it to handle new actions. Should return [true]
## if an action is handled by this method. This informs
## [Character2D] that the current action is handled
## and it should not default to a character's 'idle' pose
func _process_additional_actions(_delta: float) -> bool:
  return false
