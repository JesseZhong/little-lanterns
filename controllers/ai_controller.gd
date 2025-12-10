@abstract class_name AiController
extends Controller

signal done_waiting

const DEFAULT_WAIT_TIME = 0.1

static var _normal_distributed_range_rng_collection: Dictionary[String, NormalDistRange] = {}

@export_subgroup('debug')
@export var debug_ai = false

var waiting: bool:
	get:
		return _wait_time > 0

var _wait_time: float = 0
var _attention: AiAttention
var _current_target: Variant  # "nullable" NodePath
var _queue: AiCommandQueue


func _ready() -> void:
	super._ready()

	# Ensure attention has been set prior.
	assert(_attention, 'Attention needs to be set in AI controller.')

	# Try to signal when an action command is completed.

	# This callback ensures that non-looping (not 'idle' or 'move')
	# animations trigger a command completion.
	_character.action_ended.connect(
		func(_action): _queue.try_finish(AiConstants.EndConditions.ACTION_COMPLETED)
	)

	# For when pathing finishes.
	_character.nav_agent.navigation_finished.connect(
		func(): _queue.try_finish(AiConstants.EndConditions.DESTINATION_REACHED)
	)

	# For when waiting is done.
	done_waiting.connect(func(): _queue.try_finish(AiConstants.EndConditions.WAITED))

	# When hit, forget what was planned next.
	_character.get_hit.connect(func(_origin): _reset())

	# When a command finishes, try to execute the next.
	_queue.command_finished.connect(_queue.execute)


func _process(delta: float) -> void:
	_advance_time(delta)

	# No targets? Do your own thang.
	if !_attention.has_targets and !waiting and !_queue.has_commands:
		_idle()

	if _attention.has_targets:
		Query.foreach(
			_attention.targets,
			func(key: NodePath, data: AiTarget): _weigh_target(key, data, delta),
		)

		# No target? Get target.
		if not _current_target:
			_current_target = Query.max(_attention.targets, func(t: AiTarget): return t.weight)

		# Ensure current target is still a valid target.
		if _current_target in _attention.targets:
			_engage_target(_attention.targets[_current_target], delta)
		else:
			_current_target = null


## Populates the normal distribution range collection with values.
static func load_normal_dists(collection: Dictionary[String, Array]) -> void:
	for n in collection:
		var a = collection[n]
		assert(len(a) == 4)
		_normal_distributed_range_rng_collection[n] = NormalDistRange.new(a[0], a[1], a[2], a[3])


## Short hand generating a normal distribution value.
static func d(distribution_name: String) -> float:
	var dist = _normal_distributed_range_rng_collection.get(distribution_name)
	return dist.value if dist else 0.0


func setup(
	own_character: Character2D,
	own_condition: CharacterCondition,
) -> void:
	super.setup(own_character, own_condition)

	# Setup the command queue.
	_queue = AiCommandQueue.new(self)

	# Resets AI state from idle or active depending if there are targets present.
	_attention.first_target_entered.connect(_reset)
	_attention.last_target_exited.connect(_reset)


func move_to(
	target_position: Vector2,
	move_type: String,
	move_power: float = 0.0,
) -> void:
	_character.act(
		move_type,
		Vector2.ZERO,
		move_power,
		target_position,
	)


# Forces character to idly wait for a certain amount of time.
func wait(wait_time: float = DEFAULT_WAIT_TIME) -> void:
	_wait_time = wait_time
	_character.act('idle')


# Skip to the next command.
func go_next():
	_queue.force_finish()


## Advance internal timers forward by the simulation delta.
func _advance_time(delta: float) -> void:
	if _wait_time > 0:
		_wait_time -= delta

		if _wait_time <= 0:
			done_waiting.emit()


## Reset the command queue and currently executing commands.
func _reset():
	_queue.reset()
	_queue.try_finish(AiConstants.EndConditions.INTERRUPTED)
	_wait_time = 0


@abstract func _weigh_target(key: NodePath, data: AiTarget, delta: float) -> void

@abstract func _idle() -> void

@abstract func _engage_target(ai_target: AiTarget, delta: float) -> void
