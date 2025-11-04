extends Character2D

func _ready() -> void:
  super._ready()

func _process_additional_actions(delta: float) -> bool:
  match(action):
    'heavy_attack':
      _heavy_attack(delta)
      return true
    _:
      return false

func _heavy_attack(_delta: float):
  smooth_play('heavy_attack_%s' % _face_direction)
