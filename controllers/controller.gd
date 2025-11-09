@abstract class_name Controller
extends Node2D

## Teams, guilds, etc.
## Determines who are allies, enemies, or neutral.
@export
var faction: String = ''

var _character: Character2D

func _ready() -> void:
  if not _character:
    print_debug('Error: Invalid characte for controller.')
  
  # Enable Y-Sorting to draw furthest characters first.
  y_sort_enabled = true

func setup(
  character: Character2D,
  ..._args
) -> void:
  _character = character
