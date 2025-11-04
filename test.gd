extends Node2D

var player_spawner = PlayerSpawner.new()

func _ready() -> void:
  player_spawner.spawn(
    self,
    Vector2(20, 10),
    'novice',
    CharacterStats.new(
      300,
      120,
      25
    ),
    {
      'follow_camera': {
        'enabled': true,
        'zoom': Vector2(4, 4)
      }
    }
  )
