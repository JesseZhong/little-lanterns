extends AIController

var _scan: Area2D
var _attention: Area2D

var _targets: Dictionary[NodePath, Variant] = {}

func _ready() -> void:
  super._ready()
  
  # Create the monitoring areas.
  _scan = _setup_ai_area(120, 2.4, 112, 128)
  _attention = _setup_ai_area(220, 3.1, 208, 232)
  
  # Attach areas to the character.
  _character.add_child(_scan)
  _character.add_child(_attention)
  
  # Wire up the handlers.
  _scan.body_entered.connect(_on_alert)
  _attention.body_exited.connect(_on_escape)
  
  _walk_to(Vector2(300, 300))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
  pass

func _on_alert(body: Node2D) -> void:
  if body.get_path() not in _targets:
    var controller = body.get_parent()
    if controller is Controller and controller != self:
      _targets[body.get_path()] = {
        'controller': controller,
        'weight': 0
      }

func _on_escape(body: Node2D) -> void:
  var path = body.get_path()
  if path in _targets:
    _targets.erase(path)
