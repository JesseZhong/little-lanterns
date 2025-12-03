@abstract
class_name AiController
extends Controller

signal done_waiting()

const DEFAULT_WAIT_TIME = 0.1

var nav_agent: NavigationAgent2D:
  get: return _agent

var waiting: bool:
  get: return _wait_time > 0

var _move_type: String = ''
var _agent: NavigationAgent2D
var _stop_pathing: bool = false
var _wait_time: float = 0
var _attention: AiAttention
var _current_target: Variant # "nullable" NodePath
var _queue: AiCommandQueue


func _ready() -> void:
  super._ready()

  # Try to signal when an action command is completed.

  # This callback ensures that non-looping (not 'idle' or 'move')
  # animations trigger a command completion.
  _character.action_ended.connect(
    func (_action):
      _queue.try_finish(AiConstants.EndConditions.ACTION_COMPLETED)
  )

  # For when pathing finishes.
  _agent.navigation_finished.connect(
    func ():
      _queue.try_finish(AiConstants.EndConditions.DESTINATION_REACHED)
  )

  # For when waiting is done.
  done_waiting.connect(
    func ():
      _queue.try_finish(AiConstants.EndConditions.WAITED)
  )

  # When hit, forget what was planned next.
  _character.get_hit.connect(
    func (_origin):
      _reset()
  )

  # When collided, stop, clear action queue,
  # and force the AI to reassess the situation.
  _character.collided.connect(_reset)

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
      func (key: NodePath, data: AiTarget):
        _weigh_target(key, data, delta),
    )
  
    # No target? Get target.
    if not _current_target:
      _current_target = Query.max(
        _attention.targets,
        func (t: AiTarget):
          return t.weight
      )

    # Ensure current target is still a valid target.
    if _current_target in _attention.targets:
      _engage_target(_attention.targets[_current_target], delta)
    else:
      _current_target = null
    

func _physics_process(_delta: float) -> void:
  if not _agent:
    return

  # Do not query when the map has never synchronized and is empty.
  if NavigationServer2D.map_get_iteration_id(_agent.get_navigation_map()) == 0:
    return

  # Stop moving once the destination is reached
  # and attempt to execute the next command.
  if _agent.is_navigation_finished() or _stop_pathing:
    _character.stop_moving()
    return

  # Continue pointing the character towards the destination.
  _character.act(
    _move_type,
    _character.position.direction_to(_agent.get_next_path_position())
  )


func setup(
  own_character: Character2D,
  own_condition: CharacterCondition,
  ...args
) -> void:
  super.setup(own_character, own_condition)
  assert(len(args) >= 3, 'AI controller setup requires at least 5 arguments.')

  assert(
    args[0] is float and args[1] is float,
    'AI controller setup requires valid attention radius values.')
  _attention = AiAttention.new(
    own_character,
    args[0],
    args[1],
    faction,
  )

  assert(
    args[2] is NavigationAgent2D,
    'AI controller setup requires a valid navigation agent.'
  )
  _agent = args[2] as NavigationAgent2D
  _agent.avoidance_layers = Collision.Layers.CHARACTER_LOWER
  _agent.set_avoidance_mask_value(Collision.Layers.CHARACTER_LOWER, true)
  _agent.set_avoidance_mask_value(Collision.Layers.ABILITIES, true)
  _agent.set_avoidance_mask_value(Collision.Layers.TERRAIN, false)
  _agent.navigation_layers = Collision.Layers.TERRAIN

  # Setup the command queue.
  _queue = AiCommandQueue.new(self)

  # Resets AI state from idle or active depending if there are targets present.
  _attention.first_target_entered.connect(_reset)
  _attention.last_target_exited.connect(_reset)

  _agent.debug_enabled = true


func move_to(
  target_position: Vector2,
  move_type: String,
) -> void:
  _stop_pathing = false
  _move_type = move_type
  _agent.target_position = target_position


# Forces character to idly wait for a certain amount of time.
func wait(wait_time: float = DEFAULT_WAIT_TIME) -> void:
  _stop_pathing = true
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


func _reset():
  _queue.clear_queue()
  _queue.try_finish(AiConstants.EndConditions.INTERRUPTED)
  _stop_pathing = true
  _wait_time = 0


@abstract
func _weigh_target(key: NodePath, data: AiTarget, delta: float) -> void


@abstract
func _idle() -> void


@abstract
func _engage_target(ai_target: AiTarget, delta: float) -> void
