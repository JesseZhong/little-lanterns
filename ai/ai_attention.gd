## Sets up up a scan range, where enemies can be alerted upon entering,
## and set an attention range, where the owner loses attention of the targets
## when they leave the area.
class_name AiAttention
extends RefCounted

signal target_entered()
signal target_exited()
signal first_target_entered()
signal last_target_exited()


enum CollisionLayers {
  TERRAIN = 1,
  CHARACTER_LOWER,
  CHARACTER_UPPER,
  ABILITIES,
  AI,
}

var has_targets: bool:
  get: return len(_targets) > 0

var targets: Dictionary[NodePath, AiTarget]:
  get: return _targets

var _targets: Dictionary[NodePath, AiTarget] = {}
var _scan: Area2D
var _attention: Area2D
var _owner: Character2D

func _init(
  character: Character2D,
  scan_radius: float,
  attention_radius: float,
) -> void:
  _scan = _setup_ai_area(scan_radius)
  _attention = _setup_ai_area(attention_radius)

  # Attach areas to the character.
  character.add_child(_scan)
  character.add_child(_attention)
  _owner = character

  # Wire up the handlers.
  _scan.body_entered.connect(_on_alert)
  _attention.body_exited.connect(_on_escape)


func _setup_ai_area(
  radius: float,
) -> Area2D:
  var collision = CollisionShape2D.new()
  var shape = CircleShape2D.new()
  var area = Area2D.new()
  shape.radius = radius
  collision.shape = shape
  area.add_child(collision)
  area.set_collision_layer_value(CollisionLayers.TERRAIN, false)
  area.set_collision_layer_value(CollisionLayers.AI, true)
  area.set_collision_mask_value(CollisionLayers.TERRAIN, false)
  area.set_collision_mask_value(CollisionLayers.CHARACTER_LOWER, true)
  area.set_collision_mask_value(CollisionLayers.ABILITIES, true)
  area.monitorable = false # Should not be "visible" to physics.
  return area


func _on_alert(body: Node2D) -> void:
  var path = body.get_path()
  if path != _owner.get_path() and path not in _targets:
    var controller = body.get_parent()
    if controller is Controller and controller != self:
      _targets[path] = AiTarget.new(controller)

      target_entered.emit()
      if len(_targets) == 1:
        first_target_entered.emit()


func _on_escape(body: Node2D) -> void:
  var path = body.get_path()
  if path in _targets:
    _targets.erase(path)

    target_exited.emit()
    if len(_targets) <= 0:
      last_target_exited.emit()