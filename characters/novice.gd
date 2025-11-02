extends Character2D

func heavy_attack(_delta: float):
  var direction = calc_face_direction(move_velocity)
  smooth_play('heavy_attack_%s' % direction)

func process_additional_actions(delta: float) -> bool:
  match(action):
    'heavy_attack':
      heavy_attack(delta)
      return true
    _:
      return false

func _ready() -> void:
  super._ready()
