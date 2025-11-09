class_name AIController
extends Controller

enum CollisionLayers {
  CHARACTER = 2,
  ATTACKS,
  AI,
}

var _agent: NavigationAgent2D
var _server_ready: bool = false

func _ready() -> void:
  super._ready()
  
  # Defer to not block _ready()
  _check_server_status.call_deferred()
  
func _physics_process(_delta: float) -> void:
  if not _server_ready or not _agent:
    return
    
  # When character reaches its desitnation, reset to idle state.
  if _agent.is_navigation_finished():
    _character.action = 'idle'
    _character.move_direction = Vector2.ZERO
    return
  
  # Continue pointing the character towards the destination.
  _character.move_direction = _character.position.direction_to(_agent.get_next_path_position())
  
func setup(character: Character2D, ...args) -> void:
  super.setup(character)
  if len(args) > 0 and args[0] is NavigationAgent2D:
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
  area.set_collision_layer_value(1, false)
  area.set_collision_layer_value(CollisionLayers.AI, true)
  area.set_collision_mask_value(1, false)
  area.set_collision_mask_value(CollisionLayers.CHARACTER, true)
  area.set_collision_mask_value(CollisionLayers.ATTACKS, true)
  area.monitorable = false # Should not be "visible" to physics.
  return area

func _check_server_status() -> void:
  await get_tree().physics_frame
  _server_ready = true
