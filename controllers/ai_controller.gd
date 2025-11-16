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
  
  if _current_target:
    _process_current_target(delta)
  
  if len(_targets) == 0:
    _process_idle(delta)
  
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
    
    if args[2] is NavigationAgent2D:
      _agent = args[0]

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

@abstract
func _process_targets(delta: float) -> void

@abstract
func _process_current_target(delta: float) -> void

@abstract
func _process_idle(delta: float) -> void
