@abstract
class_name Spawner
extends Node

@abstract
func spawn(
  world: Node,
  spawn_location: Vector2,
  character_name: String,
  character_stats: CharacterStats,
  options: Dictionary[String, Variant] = {}
) -> void
