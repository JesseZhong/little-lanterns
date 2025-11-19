@abstract
class_name AiController
extends Controller

signal done_waiting()


const DEFAULT_WAIT_TIME = 0.1


var nav_agent: NavigationAgent2D:
  get: return _agent

var waiting: bool:
  get: return _wait_time > 0

var _agent: NavigationAgent2D
var _server_ready: bool = false
var _wait_time: float = 0

var _attention: AiAttention
var _current_target: Variant # "nullable" NodePath
var _queue: AiCommandQueue


func _ready() -> void:
  super._ready()
  
  # Defer to not block _ready()
  _check_server_status.call_deferred()

  # Try to execute next action when a current action is complete.
  _character.action_ended.connect(func (_action: String): _queue.execute())
  done_waiting.connect(_queue.execute)
  

func _process(delta: float) -> void:
  _advance_time(delta)

  # No targets? Do your own thang.
  if !_attention.has_targets and _character.is_idle and !waiting:
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
  if not _server_ready or not _agent:
    return

  if _agent.is_navigation_finished():
    _character.move_direction = Vector2.ZERO
    return
  
  # Continue pointing the character towards the destination.
  _character.move_direction = _character.position.direction_to(_agent.get_next_path_position())


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
    args[1]
  )

  assert(
    args[2] is NavigationAgent2D,
    'AI controller setup requires a valid navigation agent.'
  )
  _agent = args[2] as NavigationAgent2D

  # Setup the command queue.
  _queue = AiCommandQueue.new(self)


# Forces character to idly wait for a certain amount of time.
func wait(wait_time: float = DEFAULT_WAIT_TIME) -> void:
  _wait_time = wait_time
  _character.move_direction = Vector2.ZERO
  _character.act('idle')


# Ensure the navigation server is ready to receive requests.
func _check_server_status() -> void:
  await get_tree().physics_frame
  _server_ready = true


## Advance internal timers forward by the simulation delta.
func _advance_time(delta: float) -> void:
  if _wait_time > 0:
    _wait_time -= delta

    if _wait_time <= 0:
      done_waiting.emit()


@abstract
func _weigh_target(key: NodePath, data: AiTarget, delta: float) -> void


@abstract
func _idle() -> void


@abstract
func _engage_target(ai_target: AiTarget, delta: float) -> void
