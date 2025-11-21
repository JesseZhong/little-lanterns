class_name Player
extends Controller

func _ready() -> void:
  super._ready()

func _process(_delta: float) -> void:
  if _character:
      var move = Vector2.ZERO
      if Input.is_action_pressed("move_right"):
        move.x += 1
      if Input.is_action_pressed("move_left"):
        move.x -= 1
      if Input.is_action_pressed("move_down"):
        move.y += 1
      if Input.is_action_pressed("move_up"):
        move.y -= 1

      if Input.is_action_pressed('light_attack'):
        _character.act('light_attack')
      elif Input.is_action_pressed('heavy_attack'):
        _character.act('heavy_attack')
      elif Input.is_action_pressed('charge_attack'):
        _character.act('charge_attack')
      elif move.length() > 0:
        _character.move_direction = move
        _character.act(
          'run'
          if Input.is_action_pressed('run')
          else 'walk'
        )
      else:
        _character.move_direction = Vector2.ZERO
