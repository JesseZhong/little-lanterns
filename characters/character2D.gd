@abstract class_name Character2D
extends CharacterBody2D

signal action_ended(action_name: String)
signal get_hit(origin_position: Vector2)
signal collided

## Default Z-Index of characters.
## NOTE: This is temporary until elevations are implemented.
const CHARACTER_PLANE: int = 20

## How much to scale down the Y movement due to perspective.
const Y_MOVEMENT_SCALE: float = 0.83


## Gets the intended the character would like to face or move in.
## For movement, this vector will be normalized and then modified
## by a character's speed stat and then used by physics to determine
## if the character can actually move to a new position.
var direction: Vector2:
	get:
		return _direction

## The current direction the character is facing.
var face_direction: String:
	get:
		return _face_direction

## Gets the current action of the character.
var current_action: String:
	get:
		return current_action

var condition: CharacterCondition:
	get:
		return _character_condition

## Navigation agent for pathfinding and avoidance.
## Note: Even player characters can have navigation 
## for things like following other players, abilities,
##  and status effects.
var nav_agent: NavigationAgent2D:
	get:
		return _nav_agent

# Optional: For detecting other characters in range.
# Currently used by AI to gauge attack range.
var attack_sense: DirectionalSenseArea:
	get:
		return _attack_sense


var _anim_player: AnimationPlayer
var _block_anim: bool = false
var _attack_area: AbilityArea

var _direction: Vector2 = Vector2.ZERO
var _face_direction: String = 'down'
var _character_condition: CharacterCondition

var _queued_action: Variant
var _current_action: String = 'idle'

var _move_power: float = 0.0
var _move_speed: float = 0.0
var _nav_movement: bool = false
var _nav_agent: NavigationAgent2D
var _attack_sense: DirectionalSenseArea


func _ready() -> void:
	_anim_player = $AnimationPlayer
	assert(_anim_player, 'Invalid animation player for character.')

	_attack_area = $AttackArea
	_nav_agent = $NavigationAgent2D

	if has_node(^'./DirectionalSenseArea'):
		_attack_sense = $DirectionalSenseArea

	# Ensure all characters and controllers are on the same plane.
	z_index = CHARACTER_PLANE

	# Enable Y-Sorting to draw furthest characters first.
	y_sort_enabled = true

	# Handle hits that come from outside.
	get_hit.connect(_on_get_hit)

	# When a non-looping animation ends,
	# attempt to reset the animation idle, run, or walk.
	_anim_player.animation_finished.connect(func(_anim_name): action_ended.emit(current_action))

	# Handle movement when using avoidance.
	_nav_agent.velocity_computed.connect(_on_velocity_computed)

	# Reset navigation movement flag when navigation finishes.
	_nav_agent.navigation_finished.connect(func (): _nav_movement = false)


## Handle the execution of actions and animations.
func _process(_delta: float) -> void:
	# Reset speed.
	_anim_player.speed_scale = 1.0

	# Determine the animation based off the
	# intended action and if animations are blocked.
	if _queued_action:
		_process_action(_queued_action)

		# Set as current.
		_current_action = _queued_action

		# Reset queued action.
		_queued_action = null

	# Play animations according to state.
	if _anim_player:
		
		# Update animation using the final calculated face direction.
		_smooth_play('%s_%s' % [_current_action, _face_direction])

		# For getting hit, attempt to reset to idle after.
		if _current_action == 'get_hit':
			_anim_player.queue('idle')


func _physics_process(delta: float) -> void:

	# If navigation movement is indicated, derive the the movement
	# direction based off the current position in the path.
	if _nav_movement:
		# Do not query when the map has yet to be synchronized and is empty.
		# Also, stop moving once the destination is reached or determined to be unreachable.
		if NavigationServer2D.map_get_iteration_id(_nav_agent.get_navigation_map()) == 0 \
			or _nav_agent.is_navigation_finished():
			_move_power = 0.0
			_direction = Vector2.ZERO

		# Otherwise, overwrite the current movement direction.
		else:
			_direction = position.direction_to(_nav_agent.get_next_path_position())

	# Normalize the movement direction regardless of source.
	var normalized_direction = _direction.normalized()

	# Calculate the velocity based off the direction and the stat-based speed.
	var new_velocity = normalized_direction * _move_speed * _move_power

	# Scale down Y movement due to perspective.
	new_velocity.y *= Y_MOVEMENT_SCALE

	# Handle movement that is dictated by the navigation agent,
	# factoring avoidance, if necessary.
	if _nav_movement:
		if _nav_agent.avoidance_enabled:
			_nav_agent.velocity = new_velocity
		else:
			_on_velocity_computed(new_velocity)

	# Otherwise, handle manual movement while factoring physics.
	else:
		if move_and_collide(new_velocity * delta):
			collided.emit()

	# Preserve the face direction based off movement direction.
	_face_direction = VectorMath.calc_face_direction(normalized_direction, true)


## Sets up character with their starting position
## and player condition.
func setup(
	start_position: Vector2,
	own_condition: CharacterCondition,
) -> void:
	position = start_position
	_character_condition = own_condition


## Attempt to perform an action and any associated movement.
func act(
	action: String,
	intended_direction: Vector2 = Vector2.ZERO,
	move_power: float = 0.0,
	target_position: Variant = null,
) -> void:
	if !_block_anim and _queued_action != 'get_hit':
		_queued_action = action
		_direction = intended_direction
		_move_power = clamp(move_power, 0, 1)

		assert(
			target_position == null or target_position is Vector2,
			'Character act\'s target position must be `null` or Vector2.'
		)
		if target_position:
			_nav_agent.target_position = target_position as Vector2
			_nav_movement = true


## Stop movement but not animation.
func stop_moving():
	_direction = Vector2.ZERO


## Turns the character to face a certain direction.
func turn(vector: Vector2) -> void:
	_direction = vector


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


## Attempts to move with the passed velocity, factoring physics.
## If the character makes contact with another body, attempts to slide passed.
func _on_velocity_computed(new_velocity: Vector2) -> void:
	velocity = new_velocity
	move_and_slide()


## Handles non-animation configuration for actions.
## Returns `true` the action was handled properly.
## Override to add handling for more actions.
func _process_action(action: String) -> bool:
	match action:
		'idle':
			_move_power = 0.0
			return true
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
