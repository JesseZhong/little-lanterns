extends Character2D

func heavy_attack(delta: float):
  var direction = calc_face_direction(velocity)
  smooth_play('heavy_attack_%s' % direction)

func process_additional_actions(action: String, delta: float) -> bool:
  match(action):
    'heavy_attack':
      heavy_attack(delta)
      return true
    _:
      return false

func _ready() -> void:
  super._ready()
