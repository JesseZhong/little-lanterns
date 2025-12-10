class_name AiTarget
extends RefCounted

## The controller of the target.
var controller: Controller:
	get:
		return _controller

## The attention weight on this target.
var weight: float = 0:
	get:
		return weight
	set(value):
		weight = value

## The state/conditon of this target.
var condition: CharacterCondition:
	get:
		if not _controller:
			return null
		return _controller.condition

## The world position of this target.
var position: Vector2:
	get:
		return _controller.character.position

var move_direction: Vector2:
	get:
		return _controller.character.direction

## Amount of hits taken from this target.
var hits_taken: int = 0

## Amount of damage taken from this target.
var damage_taken: int = 0

## Amount of time attention has been on this target.
var attention_time: float = 0

## Amount of time this target has been focused.
var target_time: float = 0

var _controller: Controller


func _init(target_controller: Controller) -> void:
	_controller = target_controller
