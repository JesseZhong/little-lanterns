class_name AbilityArea
extends Area2D

signal deflected(area: AbilityArea)

const MIN_ABILITY_PRIORITY = 2

@export
var deflectable: bool = true

@export
var harmful: bool = true

var _deflected: bool = false
var _contacted: Dictionary[NodePath, Character2D]

func _ready() -> void:
  # Ensure priorities are set for abilities.
  # Note: Area collisions are always processed before world collisions.
  # See: https://docs.godotengine.org/en/stable/classes/class_area2d.html#class-area2d-property-priority
  assert(priority >= MIN_ABILITY_PRIORITY, 'Ability area does meet minimum priority.')
  
  area_entered.connect(_on_area_enter)
  area_exited.connect(_on_area_exit)
  body_entered.connect(_on_body_enter)
  body_exited.connect(_on_body_exit)
  
## Clear previous contacts and
## opens a deflect/parryable window.
func make_contact() -> void:
  _contacted.clear()
  _deflected = false
  
# Execute effect on all contacted targets.
# Parryable and was parried, the effect does nothing.
# If an ability is harmful, trigger effect on the receiving character.
func trigger_effect(effect: Callable) -> void:
  assert(effect, 'Invalid effect passed to ability.')
  if not _deflected:
    Query.foreach(
      _contacted,
      func (character: Character2D) -> void:
        effect.call(character)
        if harmful:
          character.get_hit.emit()
    )

## If this area is deflectable/parryable, another area
## interacting with it will cause it to be rendered useless.
func _on_area_enter(area: Area2D) -> void:
  if area.get_parent() != get_parent():
    print('IN')
  if area is AbilityArea:
    if deflectable:
      _deflected = true
      deflected.emit(area as AbilityArea)
      

func _on_area_exit(area: Area2D) -> void:
  if area.get_parent() != get_parent():
    print('OUT')
    
## Track any bodies contacted by the ability area.
## Deflected/parried abilities will stop further tracking.
func _on_body_enter(body: Node2D) -> void:
  print('SHIT')
  if not _deflected and body is Character2D:
    _contacted[body.get_path()] = body as Character2D

## Untrack any bodies that are no longer in the ability area.
func _on_body_exit(body: Node2D) -> void:
  var path = body.get_path()
  if path in _contacted:
    _contacted.erase(path)
