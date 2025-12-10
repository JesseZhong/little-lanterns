@abstract class_name Controller
extends Node2D

## Teams, guilds, etc.
## Determines who are allies, enemies, or neutral.
@export var faction: String = ''

var character: Character2D:
	get:
		return _character

var condition: CharacterCondition:
	get:
		return _condition

var _character: Character2D
var _condition: CharacterCondition


func _ready() -> void:
	# Enable Y-Sorting to draw furthest characters first.
	y_sort_enabled = true


func setup(
	own_character: Character2D,
	own_condition: CharacterCondition,
) -> void:
	_character = own_character
	_condition = own_condition
