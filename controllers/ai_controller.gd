@abstract
class_name AIController
extends Controller

signal destination_reached

enum CollisionLayers {
  TERRAIN = 1,
  CHARACTER_LOWER,
  CHARACTER_UPPER,
  ABILITIES,
  AI,
}

var _scan: Area2D
var _attention: Area2D

var _agent: NavigationAgent2D
var _server_ready: bool = false

var _targets: Dictionary[NodePath, AiTarget] = {}
var _current_target: NodePath
var _action_queue: Array = []

func _ready() -> void:
  super._ready()
  
  # Defer to not block _ready()
  _check_server_status.call_deferred()

  # Try to execute next action when a current action is complete.
  _character.action_ended.connect(func (_action: String): _on_action_complete())
  
func _process(delta: float) -> void:
  if len(_targets):
    _process_targets(delta)
  
    # No target? Get target.
    if not _current_target:
      _current_target = Query.max(
        _targets,
        func (t: AiTarget):
          return t.weight
      )
    else:
      # No targets? Do your own thang.
      _process_idle(delta)
  
  if _current_target and !len(_action_queue):
    _process_current_target(delta, _targets[_current_target])
    
  
func _physics_process(_delta: float) -> void:
  if not _server_ready or not _agent:
    return
    
  # When character reaches its desitnation, reset to idle state.
  if _agent.is_navigation_finished():
    _character.action = 'idle'
    _character.move_direction = Vector2.ZERO
    destination_reached.emit()
    return
  
  # Continue pointing the character towards the destination.
  _character.move_direction = _character.position.direction_to(_agent.get_next_path_position())
  
func setup(
  own_character: Character2D,
  own_condition: CharacterCondition,
  ...args
) -> void:
  super.setup(own_character, own_condition)
  
  if len(args) > 2:
    if args[0] is Area2D and args[1] is Area2D:
      _scan = args[0]
      _attention = args[1]
      
      # Attach areas to the character.
      own_character.add_child(_scan)
      own_character.add_child(_attention)
      
      # Wire up the handlers.
      _scan.body_entered.connect(_on_alert)
      _attention.body_exited.connect(_on_escape)
    
    assert(
      args[2] is NavigationAgent2D,
      'Invalid navigation agent passed to AI controller.'
    )
    _agent = args[2] as NavigationAgent2D

func _walk_to(target: Vector2) -> void:
  _agent.target_position = target
  _character.action = 'walk'
  
func _run_to(target: Vector2) -> void:
  _agent.target_position = target
  _character.action = 'run'

func _setup_ai_area(
  mean: float,
  deviation: float,
  low: float,
  high: float,
) -> Area2D:
  var collision = CollisionShape2D.new()
  var shape = CircleShape2D.new()
  var area = Area2D.new()
  shape.radius = NormalDistRange.generate(
    mean,
    deviation,
    low,
    high,
  )
  collision.shape = shape
  area.add_child(collision)
  area.set_collision_layer_value(CollisionLayers.TERRAIN, false)
  area.set_collision_layer_value(CollisionLayers.AI, true)
  area.set_collision_mask_value(CollisionLayers.TERRAIN, false)
  area.set_collision_mask_value(CollisionLayers.CHARACTER_LOWER, true)
  area.set_collision_mask_value(CollisionLayers.ABILITIES, true)
  area.monitorable = false # Should not be "visible" to physics.
  return area

func _check_server_status() -> void:
  await get_tree().physics_frame
  _server_ready = true
  
func _on_alert(body: Node2D) -> void:
  if body.get_path() not in _targets:
    var controller = body.get_parent()
    if controller is Controller and controller != self:
      _targets[body.get_path()] = AiTarget.new(controller)

func _on_escape(body: Node2D) -> void:
  var path = body.get_path()
  if path in _targets:
    _targets.erase(path)

## Dequeues the action queue when a current action finishes.
func _on_action_complete():
  if len(_action_queue):
    var ai_action: Callable = _action_queue.pop_back()
    ai_action.call()

func _enqueue_action(handler: Callable) -> void:
  assert(handler, 'Action handler can not be null in AI controller.')
  _action_queue.push_front(handler)

@abstract
func _process_targets(delta: float) -> void

@abstract
func _process_current_target(delta: float, ai_target: AiTarget) -> void

@abstract
func _process_idle(delta: float) -> void
