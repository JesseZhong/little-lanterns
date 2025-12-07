extends AiController

const ATTENTION = {
	range = 220,
	low_att_dist = 140,
}

const PARALLEL_THRESHOLD = 0.12

## To prevent AI from over committing to a path,
## rush over small distances and reassess.
const RUSH_DISTANCE = 23

var _patrol_target: Vector2

static func _static_init():
	load_normal_dists({
		# Attention areas.
		'att: scan range' = [120, 2.4, 112, 128],
		'att: attention range' = [ATTENTION.range, 3.1, 208, 232],
		'att: maintain attention range' = [40, 1.4, 35, 45],

		# Target weight modifiers.
		'wm: near target' = [0.4, 0.0024, 0.38, 0.42],
		'wm: far target' = [0.2, 0.0016, 0.19, 0.21],
		'wm: target hp' = [0.3, 0.02, 0.15, 0.45],
		'wm: target landed hits' = [0.5, 0.015, 0.4, 0.6],
		'wm: target landed damage' = [0.6, 0.018, 0.5, 0.7],

		# Idle.
		'i: walk distance' = [54, 3.2, 40, 65],
		'i: pause time' = [1.7, 0.26, 0, 3.0],

		# Attacks.
		'atk: approach distance' = [12, 0.58, 9, 15],
		'atk: approach side variance' = [0, 1.5, -7, 7],
		'atk: circling distance' = [32, 2.1, 25, 40],
		'atk: threat distance' = [24, 0.8, 20, 28],
		'atk: evade distance' = [22, 1.15, 16, 27],
		'atk: pause time' = [2, 0.5, 0, 4.5],

		# Watch/assess.
		'w: stalking distance' = [37, 5.8, 20, 60],
		'w: circling distance' = [54, 6.5, 30, 80]
	})


func _ready() -> void:
	super._ready()


func setup(own_character: Character2D, own_condition: CharacterCondition, ...args):
	# Variadic arguments currently don't have a spread operator
	# to compliment it. The workaround is to use `callv` to pass
	# the arguments. Unfortunately, this is the only way to
	# convert a base/super method into a callable.
	# See: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#variadic-functions
	var base_setup = func(params):
		(
			super
			. setup(
				own_character,
				own_condition,
				# Create the monitoring areas.
				d('att: scan range'),
				d('att: attention range'),
				params,
			)
		)
	base_setup.callv(args)
	_patrol_target = own_character.position


func _weigh_target(key: NodePath, data: AiTarget, delta_since: float) -> void:
	var weight = 0.0
	var target_condition = data.condition

	# Precaution: If the target doesn't exist anymore, skip.
	if not target_condition:
		return

	# See how far the target is to this character.
	# Weigh closer, higher. Also, weigh really far away higher.
	var distance = (data.position as Vector2 - position).length()
	var diff = distance - ATTENTION.low_att_dist
	weight += (
		abs(diff) * d('wm: near target') if diff < 0 else d('wm: far target') * diff
	)

	# The lower the percentage health, higher attention.
	var percent_hp = target_condition.current_hp / target_condition.max_hp.value
	weight += (1 - percent_hp) * d('wm: target hp')

	# Hits taken from target.
	weight += data.hits_taken * d('wm: target landed hits')

	# Damage taken from target.
	weight += data.damage_taken * d('wm: target landed damage')

	# If already current target, maybe maintain.
	if _current_target == key:
		weight += d('att: maintain attention range')
		data.target_time += delta_since

	data.weight = weight
	data.attention_time += delta_since


func _idle():
	_queue.do(
		HumanoidCommands.wander_patrol(
			_patrol_target,
			d('i: walk distance'), PI * 0.7, d('i: pause time'),
			debug_ai,
		)
	)


func _engage_target(ai_target: AiTarget, _delta: float) -> void:
	if !_queue.has_commands:
		var distance = (character.position - ai_target.position).length()

		# Too far? Run closer.
		if distance > ATTENTION.low_att_dist:
			_queue.do(HumanoidCommands.approach(
				ai_target,
				RUSH_DISTANCE,
				'run',
				debug_ai,
			))

		# Target is walking away, try to walk parallel or circle.
		if ai_target.move_direction != Vector2.ZERO and VectorMath.relative_movement(
			VectorMath.RelativeMovement.PARALLEL,
			PARALLEL_THRESHOLD,
			ai_target.position,
			character.position,
			ai_target.move_direction
		):
			RNG.decide(
				[
					0.3,
					func (): _queue.do(HumanoidCommands.pause(
						d('atk: pause time'),
						debug_ai,
					))
				],
				[
					0.5,
					func (): _queue.do(HumanoidCommands.circle(
						self,
						ai_target.position,
						d('w: circling distance'),
						RNG.coin_flip(),
						'walk',
						debug_ai,
					))
				],
				[
					0.2,
					func (): _queue.do(HumanoidCommands.stalk(
						ai_target,
						d('w: stalking distance'),
						debug_ai,
					))
				]
			)

		# Target walking towards.
		# Backstep and attack or heavy attack.
		elif distance < d('atk: threat distance') and VectorMath.relative_movement(
			VectorMath.RelativeMovement.TOWARD,
			PARALLEL_THRESHOLD,
			ai_target.position,
			character.position,
			ai_target.move_direction
		):
			RNG.decide(
				[
					0.2,
					func (): _queue.do(HumanoidCommands.evade_strike(
						self,
						ai_target,
						d('atk: evade distance'),
						'light_attack' if RNG.coin_flip() else 'heavy_attack',
						debug_ai,
					))
				],
				[
					0.8,
					func (): _queue.do(HumanoidCommands.careful_strike(
						ai_target,
						'heavy_strike',
						debug_ai,
					))
				]
			)

		# Approach and attack.
		else:
			RNG.decide(
				[
					0.5,
					func (): _queue.do(HumanoidCommands.circle(
						self,
						ai_target.position,
						d('atk: circling distance'),
						RNG.coin_flip(),
						'run',
						debug_ai,
					))
				],
				[
					2.0,
					func (): _queue.do([
						HumanoidCommands.rush(
							ai_target,
							d('atk: approach distance'),
							d('atk: approach side variance'),
							debug_ai,
						),
						HumanoidCommands.careful_strike(
							ai_target,
							'light_attack' if RNG.coin_flip() else 'heavy_attack',
							debug_ai,
						),
					])
				]
			)
