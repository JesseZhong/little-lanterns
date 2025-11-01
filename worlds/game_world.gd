extends Node2D

func _process(_delta: float) -> void:
  
  # Have camera follow the player.
  if $Player:
    $Camera2D.position = $Player.current_position
