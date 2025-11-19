@abstract class_name Character2D
extends CharacterBody2D

signal action_ended(action_name: String)
signal get_hit(origin_position: Vector2)

## Default Z-Index of characters.
const CHARACTER_PLANE: int = 20

## How much to scale down the Y movement due to perspective.
const Y_MOVEMENT_SCALE: float = 0.83

## Sets the intended movement direction
## of the character. This will be normalized
## and then modified by a character's speed
## state and then used by physics to determine
## if the character can actually move to
## a new position.
var move_direction: Vector2 = Vector2.ZERO

## Gets the current action of the character.
var current_action: String:
  get: return _current_action

var is_idle: bool:
  get: return _current_action == 'idle'

var condition: CharacterCondition:
  get:
    return _character_condition

var _anim_player: AnimationPlayer
var _attack_area: AbilityArea
var _character_condition: CharacterCondition
var _block_anim: bool = false
var _face_direction: String = 'down'
var _move_speed: float = 0.0
var _current_action: String = 'idle'


func _ready() -> void:
  _anim_player = $AnimationPlayer
  _attack_area = $AttackArea
  
  assert(_anim_player, 'Invalid animation player for character.')
  
  # Ensure all characters and controllers are on the same plane.
  z_index = CHARACTER_PLANE
  
  # Enable Y-Sorting to draw furthest characters first.
  y_sort_enabled = true
  
  _anim_player.animation_finished.connect(
    func (_anim_name: String):
      action_ended.emit(current_action)
  )
  get_hit.connect(_on_get_hit)


func _process(_delta: float) -> void:
  # Handle any movement animation.
  if move_direction.length() > 0 and (current_action == 'run' or current_action == 'walk'):
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
    _face_direction = VectorMath.calc_face_direction(move_direction, true)


func _physics_process(delta: float) -> void:
  # Handle movement.
  if _character_condition:
    var movement = move_direction.normalized() * _move_speed * delta
    movement.y *= Y_MOVEMENT_SCALE # Scale down Y movement due to perspective.
    move_and_collide(movement)


func setup(
  start_position: Vector2,
  own_condition: CharacterCondition
) -> void:
  position = start_position
  _character_condition = own_condition


func act(action: String) -> void:
  # Reset speed.
  _anim_player.speed_scale = 1.0

  # Determine the animation based off the
  # intended action and if animations are blocked.
  if _anim_player and !_block_anim:
    match(action):
      'idle':
        _idle()
      'walk':
        _walk()
      'run':
        _run()
      'light_attack':
        _light_attack()
      _:
        if not _process_additional_actions(action):
          _idle()

    _current_action = action


func teleport(
  target_position: Vector2
):
  # TODO: Perform a physics safety check.
  position = target_position


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


## Sets character to 'idle'.
func _idle():
  move_direction = Vector2.ZERO
  smooth_play('idle')


func _walk():
  _move_speed = _character_condition.walk_speed


func _run():
  _anim_player.speed_scale = _character_condition.run_modifier.value
  _move_speed = _character_condition.run_speed


func _get_hit():
  smooth_play('hit_%s' % _face_direction)
  _anim_player.queue('idle')

  
## Perform a light attack. Temporarily stop any character movement.
## Can be overridden. For instance, for passive
## characters, override to do nothing.
func _light_attack():
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
func _process_additional_actions(_action: String) -> bool:
  return false


## Handle any attacks hitting the character.
## If the character has super armor, shrug off hit.
func _on_get_hit(origin_position: Vector2) -> void:
  if not _character_condition.has_super_armor:
    _face_direction = VectorMath.calc_face_direction(origin_position - global_position, true)
    _get_hit()
