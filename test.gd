extends Node2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
  if $Player:
    $Camera2D.position = $Player.current_position
