## Sets up up a scan range, where enemies can be alerted upon entering,
## and set an attention range, where the owner loses attention of the targets
## when they leave the area.
class_name AiAttention
extends RefCounted

signal target_entered()
signal target_exited()
signal ally_entered()
signal ally_exited()
signal first_target_entered()
signal last_target_exited()

var has_targets: bool:
  get: return len(_targets) > 0

var targets: Dictionary[NodePath, AiTarget]:
  get: return _targets

var allies: Dictionary[NodePath, AiTarget]:
  get: return _allies

var _targets: Dictionary[NodePath, AiTarget] = {}
var _allies: Dictionary[NodePath, AiTarget] = {}
var _scan: Area2D
var _attention: Area2D
var _owner: Character2D
var _faction: String

func _init(
  character: Character2D,
  scan_radius: float,
  attention_radius: float,
  faction: String,
) -> void:
  _faction = faction
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
  area.set_collision_layer_value(Collision.Layers.TERRAIN, false)
  area.set_collision_layer_value(Collision.Layers.AI, true)
  area.set_collision_mask_value(Collision.Layers.TERRAIN, false)
  area.set_collision_mask_value(Collision.Layers.CHARACTER_LOWER, true)
  area.set_collision_mask_value(Collision.Layers.ABILITIES, true)
  area.monitorable = false # Should not be "visible" to physics.
  return area


func _on_alert(body: Node2D) -> void:
  var path = body.get_path()
  if path != _owner.get_path() and path not in _targets:
    var controller = body.get_parent() as Controller

    # Ignore self.
    if controller and controller != self:
      if controller.faction and controller.faction != _faction:
        _targets[path] = AiTarget.new(controller)

        target_entered.emit()
        if len(_targets) == 1:
          first_target_entered.emit()
      else:
        _allies[path] = AiTarget.new(controller)

        ally_entered.emit()


func _on_escape(body: Node2D) -> void:
  var path = body.get_path()
  if path in _targets:
    _targets.erase(path)

    target_exited.emit()
    if len(_targets) <= 0:
      last_target_exited.emit()

  if path in _allies:
    _allies.erase(path)

    ally_exited.emit()