@abstract class_name Character2D
extends CharacterBody2D

signal action_ended(action_name: String)
signal get_hit(origin_position: Vector2)
signal collided

## Default Z-Index of characters.
const CHARACTER_PLANE: int = 20

## How much to scale down the Y movement due to perspective.
const Y_MOVEMENT_SCALE: float = 0.83

## Gets the intended movement direction
## of the character.
## This will be normalized
## and then modified by a character's speed
## state and then used by physics to determine
## if the character can actually move to
## a new position.
var movement_direction: Vector2:
	get:
		return _move_direction

## Gets the current action of the character.
var current_action: String:
	get:
		return current_action

var condition: CharacterCondition:
	get:
		return _character_condition

# Optional: For detecting other characters in range.
# Currently used by AI to gauge attack range.
var attack_sense: DirectionalSenseArea:
	get:
		return _attack_sense

var _anim_player: AnimationPlayer
var _attack_area: AbilityArea
var _character_condition: CharacterCondition
var _block_anim: bool = false
var _face_direction: String = 'down'
var _move_speed: float = 0.0
var _move_direction: Vector2 = Vector2.ZERO
var _queued_action: Variant
var _current_action: String = 'idle'
var _attack_sense: DirectionalSenseArea


func _ready() -> void:
	_anim_player = $AnimationPlayer
	_attack_area = $AttackArea
	_attack_sense = $DirectionalSenseArea

	assert(_anim_player, 'Invalid animation player for character.')

	# Ensure all characters and controllers are on the same plane.
	z_index = CHARACTER_PLANE

	# Enable Y-Sorting to draw furthest characters first.
	y_sort_enabled = true

	# Handle hits that come from outside.
	get_hit.connect(_on_get_hit)

	# When a non-looping animation ends,
	# attempt to reset the animation idle, run, or walk.
	_anim_player.animation_finished.connect(func(_anim_name): action_ended.emit(current_action))


func _process(_delta: float) -> void:
	# Reset speed.
	_anim_player.speed_scale = 1.0

	# Determine the animation based off the
	# intended action and if animations are blocked.
	if _anim_player and _queued_action:
		match _queued_action:
			'idle':
				_idle()
			'walk' when _move_direction.length() > 0:
				_walk()
			'run' when _move_direction.length() > 0:
				_run()
			'get_hit':
				_get_hit()
			'light_attack':
				_light_attack()
			var a:
				if not _process_additional_actions(a):
					_idle()

		# Set as current.
		_current_action = _queued_action

		# Reset queued action.
		_queued_action = null


func _physics_process(delta: float) -> void:
	# Handle movement.
	if _character_condition:
		var movement = _move_direction.normalized() * _move_speed * delta
		movement.y *= Y_MOVEMENT_SCALE  # Scale down Y movement due to perspective.
		if move_and_collide(movement):
			collided.emit()


func setup(start_position: Vector2, own_condition: CharacterCondition) -> void:
	position = start_position
	_character_condition = own_condition


## Attempt to perform an action and any associated movement.
func act(action: String, movement: Vector2 = Vector2.ZERO) -> void:
	if !_block_anim and _queued_action != 'get_hit':
		_queued_action = action
		_move_direction = movement


## Stop movement but not animation.
func stop_moving():
	_move_direction = Vector2.ZERO


## Perform an in place face direction change.
func turn(vector: Vector2) -> void:
	_face_direction = VectorMath.calc_face_direction(vector, true)


func teleport(target_position: Vector2):
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


func _idle():
	_move_direction = Vector2.ZERO
	_smooth_play('idle')


func _walk():
	_move_speed = _character_condition.walk_speed
	_move()


func _run():
	_anim_player.speed_scale = _character_condition.run_modifier.value
	_move_speed = _character_condition.run_speed
	_move()


func _move():
	var x = _move_direction.x
	var y = _move_direction.y
	if abs(y) > abs(x):
		if y > 0:
			_smooth_play('walk_down')
		elif y < 0:
			_smooth_play('walk_up')
	else:
		if x > 0:
			_smooth_play('walk_right')
		elif x < 0:
			_smooth_play('walk_left')

	# Preserve the face direction for all other actions.
	_face_direction = VectorMath.calc_face_direction(_move_direction, true)


func _get_hit():
	_move_direction = Vector2.ZERO
	_smooth_play('hit_%s' % _face_direction)
	_anim_player.queue('idle')


## Perform a light attack. Temporarily stop any character movement.
## Can be overridden. For instance, for passive
## characters, override to do nothing.
func _light_attack():
	_move_direction = Vector2.ZERO
	_smooth_play('light_attack_%s' % _face_direction)


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
func _smooth_play(animation_name: String):
	if animation_name != _anim_player.assigned_animation:
		_anim_player.play('RESET')
		_anim_player.advance(0)
	_anim_player.play(animation_name)


## Handle any attacks hitting the character.
## If the character has super armor, shrug off hit.
func _on_get_hit(origin_position: Vector2) -> void:
	if not _character_condition.has_super_armor:
		# NOTE: Getting hit takes precedent over everything else and ignore animation blocks.
		_queued_action = 'get_hit'
		_face_direction = VectorMath.calc_face_direction(origin_position - global_position, true)
